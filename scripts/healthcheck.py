#!/usr/bin/env python3
"""Health check for core-api and ai-service. Exit 0 if all healthy, 1 otherwise.

Usage:
    ./scripts/healthcheck.py
    ./scripts/healthcheck.py --format json
    ./scripts/healthcheck.py --timeout 3 --retries 2
"""
from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.error
import urllib.request

DEFAULT_SERVICES = [
    ("core-api", "http://localhost:8080/health"),
    ("ai-service", "http://localhost:8081/healthz"),
]


def _http_get(url: str, timeout: float) -> tuple[int, float]:
    """Return (status_code, elapsed_seconds). Raises on network errors."""
    start = time.monotonic()
    req = urllib.request.Request(url, method="GET")
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.status, time.monotonic() - start


def _parse_services(value: str) -> list[tuple[str, str]]:
    """Parse 'name=url,name=url' from --service flag."""
    out = []
    for item in value.split(","):
        item = item.strip()
        if not item:
            continue
        if "=" not in item:
            raise argparse.ArgumentTypeError(f"invalid service spec: {item!r}")
        name, url = item.split("=", 1)
        out.append((name.strip(), url.strip()))
    return out


def check_service(name: str, url: str, timeout: float, retries: int) -> dict:
    """Try up to retries+1 times with exponential backoff. Returns a result dict."""
    last_error = None
    last_status = None
    for attempt in range(1, retries + 2):
        try:
            status, elapsed = _http_get(url, timeout)
            ok = 200 <= status < 300
            return {
                "name": name, "url": url, "ok": ok,
                "status": status,
                "latency_ms": round(elapsed * 1000, 1),
                "attempts": attempt,
                "error": None if ok else f"HTTP {status}",
            }
        except urllib.error.HTTPError as exc:
            last_status, last_error = exc.code, f"HTTP {exc.code}"
        except (urllib.error.URLError, TimeoutError) as exc:
            last_status, last_error = None, str(exc)
        if attempt <= retries:
            time.sleep(2 ** (attempt - 1))
    return {
        "name": name, "url": url, "ok": False,
        "status": last_status, "latency_ms": None,
        "attempts": retries + 1, "error": last_error or "unknown error",
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--timeout", type=float, default=5.0,
                        help="per-request timeout in seconds (default: 5)")
    parser.add_argument("--retries", type=int, default=3,
                        help="retries after first failure (default: 3)")
    parser.add_argument("--format", choices=("text", "json"), default="text")
    parser.add_argument("--service", action="append", type=_parse_services,
                        help="override services as 'name=url' (repeatable)")
    args = parser.parse_args(argv)

    if args.service:
        services = [item for group in args.service for item in group]
    else:
        services = list(DEFAULT_SERVICES)

    results = [check_service(name, url, args.timeout, args.retries)
               for name, url in services]
    all_ok = all(r["ok"] for r in results)

    if args.format == "json":
        print(json.dumps({"ok": all_ok, "services": results}, indent=2))
    else:
        for r in results:
            tag = "OK" if r["ok"] else "FAIL"
            if r["ok"]:
                detail = f"status={r['status']} latency={r['latency_ms']}ms"
            else:
                detail = r["error"]
            print(f"[{tag}] {r['name']} ({r['url']}) {detail} attempts={r['attempts']}")

    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
