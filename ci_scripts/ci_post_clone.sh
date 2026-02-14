#!/bin/sh
set -eu

# Enable unattended Swift package plugin/macro execution in Xcode Cloud.
# SwiftLint documents the misspelled key below; set both spellings for compatibility.
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidation -bool YES
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES

# Keep Xcode project versions aligned with repo VERSION metadata.
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SYNC_SCRIPT="$REPO_ROOT/scripts/sync-xcode-version.sh"

if [ ! -x "$SYNC_SCRIPT" ]; then
  echo "error: missing executable sync script at $SYNC_SCRIPT" >&2
  exit 1
fi

if [ -n "${CI_BUILD_NUMBER:-}" ]; then
  "$SYNC_SCRIPT" --build-number "$CI_BUILD_NUMBER"
else
  "$SYNC_SCRIPT"
fi
