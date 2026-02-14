#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/sync-xcode-version.sh [options]

Sync Xcode project version settings from repo metadata.

Options:
  --version-file <path>        Path to VERSION file (default: VERSION at repo root)
  --project <path>             Path to .xcodeproj (default: auto-detect single project)
  --marketing-version <x.y.z>  Override semantic marketing version
  --build-number <integer>     Set CURRENT_PROJECT_VERSION to a numeric build number
  -h, --help                   Show this help

Examples:
  scripts/sync-xcode-version.sh
  scripts/sync-xcode-version.sh --build-number 42
  scripts/sync-xcode-version.sh --project Charstack.xcodeproj --version-file VERSION
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION_FILE="$REPO_ROOT/VERSION"
PROJECT_PATH=""
MARKETING_VERSION=""
BUILD_NUMBER="${BUILD_NUMBER:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version-file)
      [[ $# -ge 2 ]] || { echo "error: --version-file requires a value" >&2; exit 1; }
      VERSION_FILE="$2"
      shift 2
      ;;
    --project)
      [[ $# -ge 2 ]] || { echo "error: --project requires a value" >&2; exit 1; }
      PROJECT_PATH="$2"
      shift 2
      ;;
    --marketing-version)
      [[ $# -ge 2 ]] || { echo "error: --marketing-version requires a value" >&2; exit 1; }
      MARKETING_VERSION="$2"
      shift 2
      ;;
    --build-number)
      [[ $# -ge 2 ]] || { echo "error: --build-number requires a value" >&2; exit 1; }
      BUILD_NUMBER="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument '$1'" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "$VERSION_FILE" != /* ]]; then
  VERSION_FILE="$REPO_ROOT/$VERSION_FILE"
fi

if [[ -z "$MARKETING_VERSION" ]]; then
  if [[ ! -f "$VERSION_FILE" ]]; then
    echo "error: VERSION file not found at '$VERSION_FILE'" >&2
    exit 1
  fi
  MARKETING_VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
fi

if [[ ! "$MARKETING_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: MARKETING_VERSION must be x.y.z (got '$MARKETING_VERSION')" >&2
  exit 1
fi

if [[ -n "$BUILD_NUMBER" ]]; then
  if [[ ! "$BUILD_NUMBER" =~ ^[0-9]+$ ]] || [[ "$BUILD_NUMBER" -le 0 ]]; then
    echo "error: build number must be a positive integer (got '$BUILD_NUMBER')" >&2
    exit 1
  fi
fi

if [[ -z "$PROJECT_PATH" ]]; then
  PROJECT_LIST="$(find "$REPO_ROOT" -maxdepth 1 -type d -name "*.xcodeproj" | sort)"
  PROJECT_COUNT="$(printf '%s\n' "$PROJECT_LIST" | sed '/^$/d' | wc -l | tr -d ' ')"
  if [[ "$PROJECT_COUNT" -eq 0 ]]; then
    echo "error: no .xcodeproj found at repo root '$REPO_ROOT'" >&2
    exit 1
  fi
  if [[ "$PROJECT_COUNT" -gt 1 ]]; then
    echo "error: multiple .xcodeproj files found; pass --project explicitly" >&2
    printf '%s\n' "$PROJECT_LIST" >&2
    exit 1
  fi
  PROJECT_PATH="$(printf '%s\n' "$PROJECT_LIST" | head -n 1)"
elif [[ "$PROJECT_PATH" != /* ]]; then
  PROJECT_PATH="$REPO_ROOT/$PROJECT_PATH"
fi

PBXPROJ="$PROJECT_PATH/project.pbxproj"
if [[ ! -f "$PBXPROJ" ]]; then
  echo "error: project file not found at '$PBXPROJ'" >&2
  exit 1
fi

export MARKETING_VERSION
export BUILD_NUMBER
python3 - "$PBXPROJ" <<'PY'
import os
import re
import sys
from pathlib import Path

pbxproj = Path(sys.argv[1])
contents = pbxproj.read_text(encoding="utf-8")

marketing_version = os.environ["MARKETING_VERSION"]
build_number = os.environ.get("BUILD_NUMBER", "")

marketing_count = 0
build_count = 0

def replace_marketing(match):
    global marketing_count
    marketing_count += 1
    return f"{match.group(1)}{marketing_version};"

def replace_build(match):
    global build_count
    build_count += 1
    return f"{match.group(1)}{build_number};"

updated = re.sub(r"(?m)^(\s*MARKETING_VERSION = )[^;]+;", replace_marketing, contents)
if marketing_count == 0:
    raise SystemExit("error: no MARKETING_VERSION settings found in project.pbxproj")

if build_number:
    updated = re.sub(r"(?m)^(\s*CURRENT_PROJECT_VERSION = )[^;]+;", replace_build, updated)
    if build_count == 0:
        raise SystemExit("error: no CURRENT_PROJECT_VERSION settings found in project.pbxproj")

if updated != contents:
    pbxproj.write_text(updated, encoding="utf-8")

print(f"Updated MARKETING_VERSION in {marketing_count} setting(s).")
if build_number:
    print(f"Updated CURRENT_PROJECT_VERSION in {build_count} setting(s).")
else:
    print("Skipped CURRENT_PROJECT_VERSION update (no --build-number provided).")
PY

echo "Synced project: $PROJECT_PATH"
echo "MARKETING_VERSION=$MARKETING_VERSION"
if [[ -n "$BUILD_NUMBER" ]]; then
  echo "CURRENT_PROJECT_VERSION=$BUILD_NUMBER"
fi
