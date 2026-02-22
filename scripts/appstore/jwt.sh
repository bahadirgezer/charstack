#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/appstore/jwt.sh

Generates a short-lived App Store Connect JWT and writes it to stdout.

Required environment variables:
  APPSTORE_API_KEY_ID
  APPSTORE_API_ISSUER_ID
  APPSTORE_API_PRIVATE_KEY or APPSTORE_API_PRIVATE_KEY_FILE

Optional environment variables:
  JWT_TTL_SECONDS  Token lifetime in seconds (default: 600, max: 1200)
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "error: missing required env var: ${name}" >&2
    exit 1
  fi
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: missing required command: $1" >&2
    exit 1
  fi
}

b64url() {
  openssl base64 -e -A | tr '+/' '-_' | tr -d '='
}

require_cmd openssl
require_cmd python3

require_env APPSTORE_API_KEY_ID
require_env APPSTORE_API_ISSUER_ID

JWT_TTL_SECONDS="${JWT_TTL_SECONDS:-600}"
if ! [[ "$JWT_TTL_SECONDS" =~ ^[0-9]+$ ]]; then
  echo "error: JWT_TTL_SECONDS must be a positive integer" >&2
  exit 1
fi
if [[ "$JWT_TTL_SECONDS" -le 0 || "$JWT_TTL_SECONDS" -gt 1200 ]]; then
  echo "error: JWT_TTL_SECONDS must be between 1 and 1200" >&2
  exit 1
fi

key_file=""
temp_key_file="false"
if [[ -n "${APPSTORE_API_PRIVATE_KEY_FILE:-}" ]]; then
  key_file="$APPSTORE_API_PRIVATE_KEY_FILE"
  if [[ ! -f "$key_file" ]]; then
    echo "error: APPSTORE_API_PRIVATE_KEY_FILE does not exist: $key_file" >&2
    exit 1
  fi
elif [[ -n "${APPSTORE_API_PRIVATE_KEY:-}" ]]; then
  key_file="$(mktemp)"
  temp_key_file="true"
  chmod 600 "$key_file"
  printf '%s\n' "$APPSTORE_API_PRIVATE_KEY" > "$key_file"
else
  echo "error: set APPSTORE_API_PRIVATE_KEY or APPSTORE_API_PRIVATE_KEY_FILE" >&2
  exit 1
fi

cleanup() {
  if [[ "$temp_key_file" == "true" ]]; then
    rm -f "$key_file"
  fi
}
trap cleanup EXIT

now="$(date +%s)"
exp="$((now + JWT_TTL_SECONDS))"

header_json="$(python3 - "$APPSTORE_API_KEY_ID" <<'PY'
import json
import sys
kid = sys.argv[1]
print(json.dumps({"alg": "ES256", "kid": kid, "typ": "JWT"}, separators=(",", ":")))
PY
)"

claims_json="$(python3 - "$APPSTORE_API_ISSUER_ID" "$now" "$exp" <<'PY'
import json
import sys
iss = sys.argv[1]
iat = int(sys.argv[2])
exp = int(sys.argv[3])
print(json.dumps({"iss": iss, "iat": iat, "exp": exp, "aud": "appstoreconnect-v1"}, separators=(",", ":")))
PY
)"

header_b64="$(printf '%s' "$header_json" | b64url)"
claims_b64="$(printf '%s' "$claims_json" | b64url)"
unsigned_token="${header_b64}.${claims_b64}"

signature_b64="$(printf '%s' "$unsigned_token" | openssl dgst -binary -sha256 -sign "$key_file" | b64url)"

printf '%s\n' "${unsigned_token}.${signature_b64}"
