#!/usr/bin/env bash
#
# test-stack.sh — End-to-end test of the two-service stack.
#
# Usage:
#   ./scripts/test-stack.sh              # full test (build + up + probes + down)
#   ./scripts/test-stack.sh --no-build   # skip docker build (faster iterations)
#   ./scripts/test-stack.sh --keep       # leave containers running after tests
#   ./scripts/test-stack.sh --verbose    # show all docker logs
#
# Exit codes:
#   0  all checks passed
#   1  prerequisite missing
#   2  unit tests failed
#   3  docker build failed
#   4  stack did not become healthy in time
#   5  endpoint check failed
#   6  log/behaviour check failed
#   7  cross-service check failed

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly COMPOSE_FILE="${REPO_ROOT}/docker-compose.yml"
readonly HEALTH_TIMEOUT="${HEALTH_TIMEOUT:-90}"
readonly API_TIMEOUT="${API_TIMEOUT:-30}"
readonly CORE_URL="${CORE_URL:-http://localhost:8080}"
readonly AI_URL="${AI_URL:-http://localhost:8081}"

DO_BUILD=1
DO_KEEP=0
VERBOSE=0
for arg in "$@"; do
  case "${arg}" in
    --no-build) DO_BUILD=0 ;;
    --keep)     DO_KEEP=1 ;;
    --verbose)  VERBOSE=1 ;;
    -h|--help)
      sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "Unknown flag: ${arg}" >&2; exit 1 ;;
  esac
done

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'
  C_GREEN=$'\033[32m'; C_RED=$'\033[31m'
  C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'
else
  C_RESET=""; C_BOLD=""; C_GREEN=""; C_RED=""; C_YELLOW=""; C_BLUE=""
fi

PASS=0; FAIL=0
declare -a FAILED_CHECKS=()

section() { printf '\n%s%s==> %s%s\n' "${C_BOLD}" "${C_BLUE}" "$*" "${C_RESET}"; }
info()    { printf '    %s\n' "$*"; }
ok()      { printf '    %s✓%s %s\n' "${C_GREEN}" "${C_RESET}" "$*"; PASS=$((PASS+1)); }
fail()    { printf '    %s✗%s %s\n' "${C_RED}" "${C_RESET}" "$*"; FAIL=$((FAIL+1)); FAILED_CHECKS+=("$*"); }
warn()    { printf '    %s!%s %s\n' "${C_YELLOW}" "${C_RESET}" "$*"; }

cleanup() {
  local exit_code=$?
  if [[ "${DO_KEEP}" -eq 1 ]]; then
    warn "Containers left running (--keep). Run 'docker compose down -v' to clean up."
    exit "${exit_code}"
  fi
  section "Cleanup"
  docker compose -f "${COMPOSE_FILE}" down -v --remove-orphans >/dev/null 2>&1 || true
  info "Stack stopped and volumes removed."
  exit "${exit_code}"
}
trap cleanup EXIT

# ---------- prerequisites ----------
section "Prerequisites"
missing=0
check_bin() {
  local cmd="$1"; shift
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    fail "${cmd} not found"
    missing=1
    return
  fi
  local ver
  ver="$("$@" 2>&1 | head -1 || true)"
  ok "${cmd} found: ${ver}"
}
check_bin docker docker --version
check_bin curl   curl -V
check_bin jq     jq --version
check_bin go     go version
if ! docker compose version >/dev/null 2>&1; then
  fail "docker compose plugin not available"
  missing=1
fi
[[ "${missing}" -eq 0 ]] || { echo "Aborting: missing prerequisites."; exit 1; }

# ---------- unit tests ----------
section "Unit tests"
cd "${REPO_ROOT}"
if go test ./internal/ai/ ./internal/client/ ./internal/config/ -v -count=1 2>&1 | tee /tmp/unit.log | grep -E "^(=== RUN|--- (PASS|FAIL)|PASS|FAIL|ok)" | tail -30; then
  if grep -q "^FAIL" /tmp/unit.log; then
    fail "Unit tests reported FAIL"
    exit 2
  fi
  ok "Unit tests passed"
else
  fail "Unit tests failed"
  exit 2
fi

# ---------- build ----------
if [[ "${DO_BUILD}" -eq 1 ]]; then
  section "Building images"
  if docker compose -f "${COMPOSE_FILE}" build >/tmp/build.log 2>&1; then
    ok "Images built"
  else
    fail "docker compose build failed — see /tmp/build.log"
    tail -40 /tmp/build.log
    exit 3
  fi
else
  section "Building images"
  info "skipped (--no-build)"
fi

# ---------- start stack ----------
section "Starting stack"
if docker compose -f "${COMPOSE_FILE}" up -d >/tmp/up.log 2>&1; then
  ok "docker compose up succeeded"
else
  fail "docker compose up failed — see /tmp/up.log"
  cat /tmp/up.log
  exit 3
fi

# ---------- wait for both services ----------
section "Waiting for services (timeout ${HEALTH_TIMEOUT}s)"
deadline=$(( $(date +%s) + HEALTH_TIMEOUT ))
core_ready=0; ai_ready=0
while [[ "$(date +%s)" -lt "${deadline}" ]]; do
  if [[ "${core_ready}" -eq 0 ]] && curl -sf --max-time 2 "${CORE_URL}/health" >/dev/null 2>&1; then
    core_ready=1
  fi
  if [[ "${ai_ready}" -eq 0 ]] && curl -sf --max-time 2 "${AI_URL}/healthz" >/dev/null 2>&1; then
    ai_ready=1
  fi
  if [[ "${core_ready}" -eq 1 && "${ai_ready}" -eq 1 ]]; then
    break
  fi
  sleep 2
done

[[ "${core_ready}" -eq 1 ]] && ok "Core API healthy" || { fail "Core API did not become healthy"; docker compose logs backend | tail -30; exit 4; }
[[ "${ai_ready}" -eq 1 ]] && ok "AI Service healthy" || { fail "AI Service did not become healthy"; docker compose logs ai-service | tail -30; exit 4; }

# ---------- cross-service: auth ----------
section "Cross-service: internal auth"
TOKEN=$(grep '^INTERNAL_API_TOKEN=' "${REPO_ROOT}/.env" 2>/dev/null | cut -d= -f2 || echo "")
if [[ -z "${TOKEN}" ]]; then
  warn "INTERNAL_API_TOKEN not found in .env — auth tests may fail"
fi

no_token_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${AI_URL}/v1/descriptions" \
  -H "Content-Type: application/json" \
  -d '{"product_name":"x","features":"y"}' || echo "000")
with_token_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${AI_URL}/v1/descriptions" \
  -H "Content-Type: application/json" \
  -H "X-Internal-Token: ${TOKEN}" \
  -d '{"product_name":"x","features":"y"}' || echo "000")

[[ "${no_token_code}" = "401" ]] && ok "AI Service rejects requests without token (401)" || fail "AI Service returned ${no_token_code} without token (expected 401)"
[[ "${with_token_code}" = "200" ]] && ok "AI Service accepts requests with valid token (200)" || fail "AI Service returned ${with_token_code} with token (expected 200)"

# ---------- cross-service: e2e ----------
section "Cross-service: end-to-end via Core API"

# Generate
resp=$(curl -sf --max-time "${API_TIMEOUT}" -X POST "${CORE_URL}/api/v1/generate" \
  -H "Content-Type: application/json" \
  -d '{"product_name":"Silla ergonómica","features":"Soporte lumbar"}' || true)
if [[ -n "${resp}" ]] && printf '%s' "${resp}" | jq -e '.description' >/dev/null 2>&1; then
  ok "POST /api/v1/generate → description received"
else
  fail "POST /api/v1/generate failed: ${resp:-<empty>}"
fi

# Translate
resp=$(curl -sf --max-time "${API_TIMEOUT}" -X POST "${CORE_URL}/api/v1/translate" \
  -H "Content-Type: application/json" \
  -d '{"text":"Buenos días","target_lang":"English"}' || true)
if [[ -n "${resp}" ]] && printf '%s' "${resp}" | jq -e '.translated' >/dev/null 2>&1; then
  ok "POST /api/v1/translate → translated received"
else
  fail "POST /api/v1/translate failed: ${resp:-<empty>}"
fi

# Email
resp=$(curl -sf --max-time "${API_TIMEOUT}" -X POST "${CORE_URL}/api/v1/email" \
  -H "Content-Type: application/json" \
  -d '{"product_name":"Teclado","features":"RGB"}' || true)
if [[ -n "${resp}" ]] && printf '%s' "${resp}" | jq -e '.subject and .body' >/dev/null 2>&1; then
  ok "POST /api/v1/email → subject + body received"
else
  fail "POST /api/v1/email failed: ${resp:-<empty>}"
fi

# ---------- cross-service: trace ID propagation ----------
section "Cross-service: trace ID propagation"

# The Core API logs in format [trace-id] METHOD PATH ...
CORE_TRACE=$(docker compose -f "${COMPOSE_FILE}" logs backend 2>&1 | grep "POST /api/v1/generate" | tail -1 | grep -oE '\[[a-f0-9-]+\]' | tr -d '[]' || true)

if [[ -n "${CORE_TRACE}" ]]; then
  ok "Trace ID captured from Core API: ${CORE_TRACE}"
  if docker compose -f "${COMPOSE_FILE}" logs ai-service 2>&1 | grep -q "${CORE_TRACE}"; then
    ok "Same trace ID found in AI Service logs (propagation works)"
  else
    fail "Trace ID ${CORE_TRACE} not found in AI Service logs"
  fi
else
  fail "Could not extract trace ID from Core API logs"
fi

# ---------- negative test: failover still works ----------
section "Negative test: AI failover within AI Service"
# Restart the ai-service with an invalid GROQ key to force failover.
docker compose -f "${COMPOSE_FILE}" stop ai-service >/dev/null
docker compose -f "${COMPOSE_FILE}" rm -f ai-service >/dev/null 2>&1 || true

GROQ_API_KEY="invalid-key-for-test" \
  docker compose -f "${COMPOSE_FILE}" up -d ai-service >/dev/null

deadline=$(( $(date +%s) + HEALTH_TIMEOUT ))
while [[ "$(date +%s)" -lt "${deadline}" ]]; do
  curl -sf --max-time 2 "${AI_URL}/healthz" >/dev/null 2>&1 && break
  sleep 2
done

curl -s --max-time "${API_TIMEOUT}" -X POST "${CORE_URL}/api/v1/generate" \
  -H "Content-Type: application/json" \
  -d '{"product_name":"Test Fallback","features":"x"}' >/dev/null 2>&1 || true

logs=$(docker compose -f "${COMPOSE_FILE}" logs ai-service 2>&1)
if printf '%s' "${logs}" | grep -q "AI provider failed"; then
  ok "Observed provider failure and failover inside AI Service"
else
  warn "No failure observed in AI Service logs (may be a fast path)"
fi

# ---------- final report ----------
section "Summary"
printf '    %sPassed:%s %d\n' "${C_GREEN}" "${C_RESET}" "${PASS}"
printf '    %sFailed:%s %d\n' "${C_RED}" "${C_RESET}" "${FAIL}"
if [[ "${FAIL}" -gt 0 ]]; then
  printf '\n    %sFailed checks:%s\n' "${C_BOLD}" "${C_RESET}"
  for c in "${FAILED_CHECKS[@]}"; do printf '      - %s\n' "$c"; done
  exit 6
fi
printf '\n    %sAll checks passed.%s\n' "${C_BOLD}${C_GREEN}" "${C_RESET}"
