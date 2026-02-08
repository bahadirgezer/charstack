#!/usr/bin/env bash
# Resolves Xcode workspace/project and scheme.
# Outputs: flag, path, scheme → $GITHUB_OUTPUT
#
# Respects these GitHub Actions vars (all optional):
#   XCODE_WORKSPACE, XCODE_PROJECT, XCODE_SCHEME
set -euo pipefail

WORKSPACE="${INPUT_WORKSPACE:-}"
PROJECT="${INPUT_PROJECT:-}"
SCHEME="${INPUT_SCHEME:-}"

# --- Auto-detect workspace/project if not specified ---
if [[ -z "$WORKSPACE" && -z "$PROJECT" ]]; then
  WORKSPACE="$(ls -1d *.xcworkspace 2>/dev/null | head -1 || true)"
  PROJECT="$(ls -1d *.xcodeproj 2>/dev/null | head -1 || true)"
fi

if [[ -n "$WORKSPACE" ]]; then
  FLAG="-workspace"
  PATH_VAL="$WORKSPACE"
elif [[ -n "$PROJECT" ]]; then
  FLAG="-project"
  PATH_VAL="$PROJECT"
else
  echo "::error::No .xcworkspace or .xcodeproj found at repo root."
  exit 1
fi

# --- Auto-detect scheme if not specified ---
if [[ -z "$SCHEME" ]]; then
  SCHEMES_JSON="$(xcodebuild "$FLAG" "$PATH_VAL" -list -json 2>/dev/null)"
  SCHEME="$(echo "$SCHEMES_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
obj = data.get('workspace') or data.get('project') or {}
schemes = obj.get('schemes', [])
if len(schemes) == 1:
    print(schemes[0])
")"
  if [[ -z "$SCHEME" ]]; then
    echo "::error::Cannot auto-detect scheme. Set vars.XCODE_SCHEME."
    exit 1
  fi
fi

echo "flag=$FLAG" >> "$GITHUB_OUTPUT"
echo "path=$PATH_VAL" >> "$GITHUB_OUTPUT"
echo "scheme=$SCHEME" >> "$GITHUB_OUTPUT"
echo "Resolved: $FLAG $PATH_VAL -scheme $SCHEME"
