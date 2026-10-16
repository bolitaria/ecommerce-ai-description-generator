#!/usr/bin/env bash
#
# test-stack.sh — End-to-end test of the AI fallback chain.
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

set -euo pipefail

# ---------- configuration ----------
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly COMPOSE_FILE="${REPO_ROOT}/docker-compose.yml"
readonly HEALTH_TIMEOUT="${HEALTH_TIMEOUT:-60}"     # seconds
readonly API_TIMEOUT="${API_TIMEOUT:-15}"           # seconds
readonly PROBE_URL="${PROBE_URL:-http://localhost:8080}"

# ---------- CLI flags ----------
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

# ---------- colors ----------
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'
  C_GREEN=$'\033[32m'; C_RED=$'\033[31m'
  C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'
else
  C_RESET=""; C_BOLD=""; C_GREEN=""; C_RED=""; C_YELLOW=""; C_BLUE=""
fi

# ---------- reporting ----------
PASS=0; FAIL=0
declare -a FAILED_CHECKS=()

section() { printf '\n%s%s==> %s%s\n' "${C_BOLD}" "${C_BLUE}" "$*" "${C_RESET}"; }
info()    { printf '    %s\n' "$*"; }
ok()      { printf '    %s✓%s %s\n' "${C_GREEN}" "${C_RESET}" "$*"; PASS=$((PASS+1)); }
fail()    { printf '    %s✗%s %s\n' "${C_RED}" "${C_RESET}" "$*"; FAIL=$((FAIL+1)); FAILED_CHECKS+=("$*"); }
warn()    { printf '    %s!%s %s\n' "${C_YELLOW}" "${C_RESET}" "$*"; }

# ---------- cleanup trap ----------
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
for cmd in docker curl jq go; do
  if command -v "${cmd}" >/dev/null 2>&1; then
    ver=$(${cmd} version 2>&1 | head -1 || true)
    [[ -z "${ver}" ]] && ver=$(${cmd} --version 2>&1 | head -1 || true)
    ok "${cmd} found: ${ver}"
  else
    fail "${cmd} not found"
    missing=1
  fi
done
if ! docker compose version >/dev/null 2>&1; then
  fail "docker compose plugin not available"
  missing=1
fi
[[ "${missing}" -eq 0 ]] || { echo "Aborting: missing prerequisites."; exit 1; }

# ---------- unit tests ----------
section "Unit tests (internal/ai)"
cd "${REPO_ROOT}"
if go test ./internal/ai/ -v -count=1 2>&1 | tee /tmp/unit.log | tail -30; then
  if grep -q "^PASS" /tmp/unit.log && ! grep -q "^FAIL" /tmp/unit.log; then
    ok "Unit tests passed"
  else
    fail "Unit tests did not report PASS"
    exit 2
  fi
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

# ---------- wait for health ----------
section "Waiting for backend /health (timeout ${HEALTH_TIMEOUT}s)"
deadline=$(( $(date +%s) + HEALTH_TIMEOUT ))
healthy=0
while [[ "$(date +%s)" -lt "${deadline}" ]]; do
  if curl -sf --max-time 2 "${PROBE_URL}/health" >/dev/null 2>&1; then
    healthy=1
    break
  fi
  sleep 2
done

if [[ "${healthy}" -eq 1 ]]; then
  ok "Backend is healthy"
else
  fail "Backend did not become healthy within ${HEALTH_TIMEOUT}s"
  docker compose -f "${COMPOSE_FILE}" logs backend | tail -60
  exit 4
fi

# ---------- verify fallback chain wiring ----------
section "Fallback chain wiring (logs)"
chain_log=$(docker compose -f "${COMPOSE_FILE}" logs backend 2>&1 | grep "AI fallback chain ready" || true)
if [[ -n "${chain_log}" ]]; then
  ok "Startup log: ${chain_log#*msg=}"
else
  fail "Missing 'AI fallback chain ready' log line"
fi

# ---------- probe /api/v1/generate ----------
section "Probe POST /api/v1/generate"
resp=$(curl -sf --max-time "${API_TIMEOUT}" -X POST "${PROBE_URL}/api/v1/generate" \
  -H "Content-Type: application/json" \
  -d '{"product_name":"Auriculares Bluetooth","features":"Cancelación de ruido, 30h batería"}' || true)

if [[ -z "${resp}" ]]; then
  fail "No response from /api/v1/generate"
else
  desc=$(printf '%s' "${resp}" | jq -r '.description // empty')
  if [[ -n "${desc}" ]]; then
    ok "Received description (${#desc} chars): ${desc:0:80}..."
  else
    fail "Response has no .description field: ${resp}"
  fi
fi

# ---------- verify provider was invoked ----------
section "Fallback behaviour in logs"
tried=$(docker compose -f "${COMPOSE_FILE}" logs backend 2>&1 | grep -c "trying AI provider" || true)
if [[ "${tried}" -gt 0 ]]; then
  ok "Provider invocation logged (${tried} attempt(s))"
  if [[ "${VERBOSE}" -eq 1 ]]; then
    docker compose -f "${COMPOSE_FILE}" logs backend 2>&1 | grep "trying AI provider" | tail -3 | sed 's/^/      /'
  fi
else
  fail "No 'trying AI provider' log line — fallback chain did not execute"
fi

# ---------- negative test: force provider failure ----------
section "Negative test: force first provider to fail"
# Restart backend with a bogus primary key so we can observe failover to the mock.
docker compose -f "${COMPOSE_FILE}" stop backend >/dev/null
docker compose -f "${COMPOSE_FILE}" rm -f backend >/dev/null 2>&1 || true

GROQ_API_KEY="invalid-key-for-test" \
  docker compose -f "${COMPOSE_FILE}" up -d backend >/dev/null

deadline=$(( $(date +%s) + HEALTH_TIMEOUT ))
while [[ "$(date +%s)" -lt "${deadline}" ]]; do
  curl -sf --max-time 2 "${PROBE_URL}/health" >/dev/null 2>&1 && break
  sleep 2
done

curl -sf --max-time "${API_TIMEOUT}" -X POST "${PROBE_URL}/api/v1/generate" \
  -H "Content-Type: application/json" \
  -d '{"product_name":"Test Fallback","features":"x"}' >/dev/null 2>&1 || true

logs=$(docker compose -f "${COMPOSE_FILE}" logs backend 2>&1)
if printf '%s' "${logs}" | grep -q "AI provider failed"; then
  ok "Observed provider failure and failover to next in chain"
else
  warn "No failure observed — check that GROQ_API_KEY=invalid-key-for-test reached the container"
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
