#!/usr/bin/env bash
set -euo pipefail

VERSION_FILE="${VERSION_FILE:-VERSION}"
PBXPROJ_FILE="${PBXPROJ_FILE:-Charstack.xcodeproj/project.pbxproj}"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "VERSION file not found: $VERSION_FILE" >&2
  exit 1
fi

if [[ ! -f "$PBXPROJ_FILE" ]]; then
  echo "Xcode project file not found: $PBXPROJ_FILE" >&2
  exit 1
fi

VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "VERSION must be x.y.z — got '$VERSION'" >&2
  exit 1
fi

BUILD_NUMBER="${BUILD_NUMBER:-}"
if [[ -z "$BUILD_NUMBER" ]]; then
  BUILD_NUMBER="$(git rev-list --count HEAD 2>/dev/null || true)"
fi
if [[ -z "$BUILD_NUMBER" ]]; then
  BUILD_NUMBER="1"
fi

python3 - <<'PY'
import os, re, sys
from pathlib import Path

pbxproj = Path(os.environ["PBXPROJ_FILE"])
version = os.environ["VERSION"]
build = os.environ["BUILD_NUMBER"]

text = pbxproj.read_text()
text2 = re.sub(r"MARKETING_VERSION = [^;]+;", f"MARKETING_VERSION = {version};", text)
text2 = re.sub(r"CURRENT_PROJECT_VERSION = [^;]+;", f"CURRENT_PROJECT_VERSION = {build};", text2)

if text2 != text:
    pbxproj.write_text(text2)
    print(f"Updated MARKETING_VERSION={version} CURRENT_PROJECT_VERSION={build}")
else:
    print("Project version already up to date.")
PY
