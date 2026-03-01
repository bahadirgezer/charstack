#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/appstore/sync_assets.sh --app-store-version-id <id> --locale <locale> [--root appstore-assets]

Synchronizes App Store screenshots and previews from source-controlled folders.

Folder layout:
  appstore-assets/screenshots/<locale>/<display-family>/*.{png,jpg,jpeg}
  appstore-assets/previews/<locale>/<display-family>/*.{mov,mp4,m4v}

Notes:
  - This script is intentionally opt-in from workflow input sync_assets.
  - In-App Events and In-App Purchases are intentionally out of scope.
USAGE
}

APP_STORE_VERSION_ID=""
LOCALE=""
ROOT_DIR="appstore-assets"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-store-version-id)
      APP_STORE_VERSION_ID="$2"
      shift 2
      ;;
    --locale)
      LOCALE="$2"
      shift 2
      ;;
    --root)
      ROOT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$APP_STORE_VERSION_ID" || -z "$LOCALE" ]]; then
  usage >&2
  exit 1
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: missing required command: $1" >&2
    exit 1
  fi
}

require_cmd python3
require_cmd curl
require_cmd dd

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASC_API="$SCRIPT_DIR/asc_api.sh"

if [[ ! -x "$ASC_API" ]]; then
  echo "error: missing ASC API helper at $ASC_API" >&2
  exit 1
fi

ensure_tmpdir() {
  mkdir -p build
}

api_get_first_id() {
  local path="$1"
  "$ASC_API" GET "$path" | python3 - <<'PY'
import json
import sys
payload = json.load(sys.stdin)
items = payload.get("data") or []
print(items[0].get("id", "") if items else "")
PY
}

ensure_version_localization() {
  local version_id="$1"
  local locale="$2"

  local loc_id
  loc_id="$(api_get_first_id "/v1/appStoreVersionLocalizations?filter[appStoreVersion]=${version_id}&filter[locale]=${locale}&limit=1")"
  if [[ -n "$loc_id" ]]; then
    printf '%s\n' "$loc_id"
    return 0
  fi

  cat > build/create-localization.json <<JSON
{
  "data": {
    "type": "appStoreVersionLocalizations",
    "attributes": {
      "locale": "${locale}"
    },
    "relationships": {
      "appStoreVersion": {
        "data": {
          "type": "appStoreVersions",
          "id": "${version_id}"
        }
      }
    }
  }
}
JSON

  "$ASC_API" POST "/v1/appStoreVersionLocalizations" build/create-localization.json | python3 - <<'PY'
import json
import sys
payload = json.load(sys.stdin)
print((payload.get("data") or {}).get("id", ""))
PY
}

ensure_screenshot_set() {
  local localization_id="$1"
  local display_type="$2"

  local set_id
  set_id="$(api_get_first_id "/v1/appScreenshotSets?filter[appStoreVersionLocalization]=${localization_id}&filter[screenshotDisplayType]=${display_type}&limit=1")"
  if [[ -n "$set_id" ]]; then
    printf '%s\n' "$set_id"
    return 0
  fi

  cat > build/create-screenshot-set.json <<JSON
{
  "data": {
    "type": "appScreenshotSets",
    "attributes": {
      "screenshotDisplayType": "${display_type}"
    },
    "relationships": {
      "appStoreVersionLocalization": {
        "data": {
          "type": "appStoreVersionLocalizations",
          "id": "${localization_id}"
        }
      }
    }
  }
}
JSON

  "$ASC_API" POST "/v1/appScreenshotSets" build/create-screenshot-set.json | python3 - <<'PY'
import json
import sys
payload = json.load(sys.stdin)
print((payload.get("data") or {}).get("id", ""))
PY
}

ensure_preview_set() {
  local localization_id="$1"
  local preview_type="$2"

  local set_id
  set_id="$(api_get_first_id "/v1/appPreviewSets?filter[appStoreVersionLocalization]=${localization_id}&filter[previewType]=${preview_type}&limit=1")"
  if [[ -n "$set_id" ]]; then
    printf '%s\n' "$set_id"
    return 0
  fi

  cat > build/create-preview-set.json <<JSON
{
  "data": {
    "type": "appPreviewSets",
    "attributes": {
      "previewType": "${preview_type}"
    },
    "relationships": {
      "appStoreVersionLocalization": {
        "data": {
          "type": "appStoreVersionLocalizations",
          "id": "${localization_id}"
        }
      }
    }
  }
}
JSON

  "$ASC_API" POST "/v1/appPreviewSets" build/create-preview-set.json | python3 - <<'PY'
import json
import sys
payload = json.load(sys.stdin)
print((payload.get("data") or {}).get("id", ""))
PY
}

content_type_for_file() {
  case "${1##*.}" in
    png|PNG) echo "image/png" ;;
    jpg|JPG|jpeg|JPEG) echo "image/jpeg" ;;
    mov|MOV) echo "video/quicktime" ;;
    mp4|MP4|m4v|M4V) echo "video/mp4" ;;
    *) echo "application/octet-stream" ;;
  esac
}

upload_from_operations() {
  local response_file="$1"
  local source_file="$2"

  local ops_tsv
  ops_tsv="$(mktemp)"

  python3 - "$response_file" > "$ops_tsv" <<'PY'
import base64
import json
import pathlib
import sys

payload = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
data = payload.get("data") or {}
attrs = data.get("attributes") or {}
ops = attrs.get("uploadOperations") or []

for op in ops:
    method = op.get("method", "PUT")
    url = op.get("url", "")
    offset = op.get("offset", 0)
    length = op.get("length", 0)
    headers = op.get("requestHeaders") or []
    b64_headers = base64.b64encode(json.dumps(headers).encode("utf-8")).decode("ascii")
    print(f"{method}\t{url}\t{offset}\t{length}\t{b64_headers}")
PY

  if [[ ! -s "$ops_tsv" ]]; then
    rm -f "$ops_tsv"
    return 0
  fi

  while IFS=$'\t' read -r method url offset length headers_b64; do
    if [[ -z "$url" ]]; then
      continue
    fi

    mapfile -t headers < <(python3 - "$headers_b64" <<'PY'
import base64
import json
import sys
headers = json.loads(base64.b64decode(sys.argv[1]).decode("utf-8"))
for h in headers:
    name = h.get("name")
    value = h.get("value")
    if name and value is not None:
        print(f"{name}: {value}")
PY
)

    curl_cmd=(curl -sS -X "$method" "$url")
    for h in "${headers[@]}"; do
      curl_cmd+=( -H "$h" )
    done

    if [[ "$length" =~ ^[0-9]+$ ]] && [[ "$length" -gt 0 ]]; then
      chunk_file="$(mktemp)"
      dd if="$source_file" of="$chunk_file" bs=1 skip="$offset" count="$length" status=none
      curl_cmd+=( --data-binary "@$chunk_file" )
      "${curl_cmd[@]}" >/dev/null
      rm -f "$chunk_file"
    else
      curl_cmd+=( --data-binary "@$source_file" )
      "${curl_cmd[@]}" >/dev/null
    fi
  done < "$ops_tsv"

  rm -f "$ops_tsv"
}

create_upload_resource() {
  local kind="$1"          # screenshot | preview
  local set_id="$2"
  local file_path="$3"

  local file_name
  file_name="$(basename "$file_path")"
  local file_size
  file_size="$(wc -c < "$file_path" | tr -d ' ')"
  local mime_type
  mime_type="$(content_type_for_file "$file_name")"

  if [[ "$kind" == "screenshot" ]]; then
    FILE_NAME="$file_name" FILE_SIZE="$file_size" SET_ID="$set_id" python3 - <<'PY' > build/create-resource.json
import json
import os
print(json.dumps({
  "data": {
    "type": "appScreenshots",
    "attributes": {
      "fileName": os.environ["FILE_NAME"],
      "fileSize": int(os.environ["FILE_SIZE"])
    },
    "relationships": {
      "appScreenshotSet": {
        "data": {"type": "appScreenshotSets", "id": os.environ["SET_ID"]}
      }
    }
  }
}))
PY
    "$ASC_API" POST "/v1/appScreenshots" build/create-resource.json > build/create-resource-response.json
  else
    FILE_NAME="$file_name" FILE_SIZE="$file_size" MIME_TYPE="$mime_type" SET_ID="$set_id" python3 - <<'PY' > build/create-resource.json
import json
import os
print(json.dumps({
  "data": {
    "type": "appPreviews",
    "attributes": {
      "fileName": os.environ["FILE_NAME"],
      "fileSize": int(os.environ["FILE_SIZE"]),
      "mimeType": os.environ["MIME_TYPE"]
    },
    "relationships": {
      "appPreviewSet": {
        "data": {"type": "appPreviewSets", "id": os.environ["SET_ID"]}
      }
    }
  }
}))
PY
    "$ASC_API" POST "/v1/appPreviews" build/create-resource.json > build/create-resource-response.json
  fi

  upload_from_operations build/create-resource-response.json "$file_path"

  resource_id="$(python3 - <<'PY'
import json
from pathlib import Path
payload = json.loads(Path("build/create-resource-response.json").read_text(encoding="utf-8"))
print((payload.get("data") or {}).get("id", ""))
PY
)"

  if [[ -z "$resource_id" ]]; then
    echo "error: missing resource ID for $file_name" >&2
    exit 1
  fi

  if [[ "$kind" == "screenshot" ]]; then
    cat > build/finalize-resource.json <<JSON
{
  "data": {
    "type": "appScreenshots",
    "id": "${resource_id}",
    "attributes": {
      "uploaded": true
    }
  }
}
JSON
    "$ASC_API" PATCH "/v1/appScreenshots/${resource_id}" build/finalize-resource.json >/dev/null || true
  else
    cat > build/finalize-resource.json <<JSON
{
  "data": {
    "type": "appPreviews",
    "id": "${resource_id}",
    "attributes": {
      "uploaded": true
    }
  }
}
JSON
    "$ASC_API" PATCH "/v1/appPreviews/${resource_id}" build/finalize-resource.json >/dev/null || true
  fi

  echo "Uploaded ${kind}: ${file_name}"
}

sync_screenshots() {
  local localization_id="$1"
  local screenshots_root="$2"

  if [[ ! -d "$screenshots_root" ]]; then
    echo "No screenshots directory at $screenshots_root"
    return 0
  fi

  local found="false"

  while IFS= read -r display_dir; do
    [[ -d "$display_dir" ]] || continue
    display_type="$(basename "$display_dir")"
    set_id="$(ensure_screenshot_set "$localization_id" "$display_type")"

    while IFS= read -r file_path; do
      [[ -f "$file_path" ]] || continue
      found="true"
      create_upload_resource screenshot "$set_id" "$file_path"
    done < <(find "$display_dir" -maxdepth 1 -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' \) | sort)
  done < <(find "$screenshots_root" -mindepth 1 -maxdepth 1 -type d | sort)

  if [[ "$found" == "false" ]]; then
    echo "No screenshot files found under $screenshots_root"
  fi
}

sync_previews() {
  local localization_id="$1"
  local previews_root="$2"

  if [[ ! -d "$previews_root" ]]; then
    echo "No previews directory at $previews_root"
    return 0
  fi

  local found="false"

  while IFS= read -r display_dir; do
    [[ -d "$display_dir" ]] || continue
    preview_type="$(basename "$display_dir")"
    set_id="$(ensure_preview_set "$localization_id" "$preview_type")"

    while IFS= read -r file_path; do
      [[ -f "$file_path" ]] || continue
      found="true"
      create_upload_resource preview "$set_id" "$file_path"
    done < <(find "$display_dir" -maxdepth 1 -type f \( -name '*.mov' -o -name '*.mp4' -o -name '*.m4v' \) | sort)
  done < <(find "$previews_root" -mindepth 1 -maxdepth 1 -type d | sort)

  if [[ "$found" == "false" ]]; then
    echo "No preview files found under $previews_root"
  fi
}

ensure_tmpdir
localization_id="$(ensure_version_localization "$APP_STORE_VERSION_ID" "$LOCALE")"
if [[ -z "$localization_id" ]]; then
  echo "error: failed to resolve appStoreVersionLocalization" >&2
  exit 1
fi

echo "Using appStoreVersionLocalization: $localization_id"

sync_screenshots "$localization_id" "$ROOT_DIR/screenshots/$LOCALE"
sync_previews "$localization_id" "$ROOT_DIR/previews/$LOCALE"
