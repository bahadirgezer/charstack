#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/appstore/asc_api.sh <METHOD> <PATH> [JSON_FILE]

Examples:
  scripts/appstore/asc_api.sh GET /v1/apps
  scripts/appstore/asc_api.sh POST /v1/betaGroups/<id>/relationships/builds payload.json

Environment:
  ASC_BASE_URL                Optional (default: https://api.appstoreconnect.apple.com)
  ASC_JWT_TOKEN               Optional pre-generated JWT
  ASC_API_MAX_RETRIES         Optional retry count for 429/5xx (default: 5)
  ASC_API_BACKOFF_BASE_SECONDS Optional base backoff seconds (default: 2)
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage >&2
  exit 1
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: missing required command: $1" >&2
    exit 1
  fi
}

normalize_error() {
  local status="$1"
  local body_file="$2"
  python3 - "$status" "$body_file" <<'PY'
import json
import pathlib
import sys

status = sys.argv[1]
body_path = pathlib.Path(sys.argv[2])
body = body_path.read_text(encoding="utf-8", errors="replace") if body_path.exists() else ""

print(f"ASC API error: HTTP {status}", file=sys.stderr)

if not body.strip():
    print("- detail: empty response body", file=sys.stderr)
    sys.exit(0)

try:
    parsed = json.loads(body)
except json.JSONDecodeError:
    print("- detail: non-JSON response body", file=sys.stderr)
    print(body[:600], file=sys.stderr)
    sys.exit(0)

errors = parsed.get("errors")
if not isinstance(errors, list) or not errors:
    detail = parsed.get("detail") or parsed.get("message") or "Unknown API error"
    print(f"- detail: {detail}", file=sys.stderr)
    sys.exit(0)

for err in errors:
    code = err.get("code", "UNKNOWN")
    title = err.get("title", "")
    detail = err.get("detail", "")
    src = err.get("source") or {}
    pointer = src.get("pointer") or src.get("parameter") or "n/a"
    suffix = f"{title}: {detail}" if title and detail else (detail or title or "")
    if suffix:
        print(f"- code={code} pointer={pointer} detail={suffix}", file=sys.stderr)
    else:
        print(f"- code={code} pointer={pointer}", file=sys.stderr)
PY
}

should_retry() {
  local status="$1"
  if [[ "$status" == "429" ]]; then
    return 0
  fi
  if [[ "$status" =~ ^5[0-9][0-9]$ ]]; then
    return 0
  fi
  return 1
}

require_cmd curl
require_cmd python3

METHOD="$(echo "$1" | tr '[:lower:]' '[:upper:]')"
PATH_PART="$2"
BODY_FILE="${3:-}"

if [[ -n "$BODY_FILE" && ! -f "$BODY_FILE" ]]; then
  echo "error: JSON file not found: $BODY_FILE" >&2
  exit 1
fi

if [[ "$PATH_PART" != /* ]]; then
  PATH_PART="/$PATH_PART"
fi

ASC_BASE_URL="${ASC_BASE_URL:-https://api.appstoreconnect.apple.com}"
MAX_RETRIES="${ASC_API_MAX_RETRIES:-5}"
BACKOFF_BASE_SECONDS="${ASC_API_BACKOFF_BASE_SECONDS:-2}"

if ! [[ "$MAX_RETRIES" =~ ^[0-9]+$ ]]; then
  echo "error: ASC_API_MAX_RETRIES must be an integer" >&2
  exit 1
fi
if ! [[ "$BACKOFF_BASE_SECONDS" =~ ^[0-9]+$ ]] || [[ "$BACKOFF_BASE_SECONDS" -le 0 ]]; then
  echo "error: ASC_API_BACKOFF_BASE_SECONDS must be a positive integer" >&2
  exit 1
fi

JWT_TOKEN="${ASC_JWT_TOKEN:-}"
if [[ -z "$JWT_TOKEN" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  JWT_TOKEN="$($SCRIPT_DIR/jwt.sh)"
fi

URL="${ASC_BASE_URL}${PATH_PART}"
ATTEMPT=0
LAST_STATUS=""

while (( ATTEMPT <= MAX_RETRIES )); do
  ATTEMPT=$((ATTEMPT + 1))

  body_tmp="$(mktemp)"
  header_tmp="$(mktemp)"

  curl_args=(
    -sS
    -X "$METHOD"
    "$URL"
    -H "Authorization: Bearer $JWT_TOKEN"
    -H "Accept: application/json"
    -D "$header_tmp"
    -o "$body_tmp"
    -w "%{http_code}"
  )

  if [[ -n "$BODY_FILE" ]]; then
    curl_args+=(
      -H "Content-Type: application/json"
      --data-binary "@$BODY_FILE"
    )
  fi

  set +e
  http_code="$(curl "${curl_args[@]}")"
  curl_exit=$?
  set -e

  if [[ $curl_exit -eq 0 && "$http_code" =~ ^2[0-9][0-9]$ ]]; then
    cat "$body_tmp"
    rm -f "$body_tmp" "$header_tmp"
    exit 0
  fi

  if [[ $curl_exit -ne 0 ]]; then
    LAST_STATUS="curl_exit_${curl_exit}"
    if (( ATTEMPT <= MAX_RETRIES )); then
      sleep_seconds=$((BACKOFF_BASE_SECONDS * ATTEMPT))
      sleep "$sleep_seconds"
      rm -f "$body_tmp" "$header_tmp"
      continue
    fi

    echo "error: curl request failed after ${ATTEMPT} attempt(s)" >&2
    rm -f "$body_tmp" "$header_tmp"
    exit 1
  fi

  LAST_STATUS="$http_code"

  if should_retry "$http_code" && (( ATTEMPT <= MAX_RETRIES )); then
    sleep_seconds=$((BACKOFF_BASE_SECONDS * ATTEMPT))
    sleep "$sleep_seconds"
    rm -f "$body_tmp" "$header_tmp"
    continue
  fi

  normalize_error "$http_code" "$body_tmp"
  rm -f "$body_tmp" "$header_tmp"
  exit 1
done

echo "error: request failed after retries (last status: ${LAST_STATUS:-unknown})" >&2
exit 1
