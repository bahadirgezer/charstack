#!/usr/bin/env bash
#
# Runs auto-fixers first (swift-format + swiftlint fix), then runs the exact
# checks your GitHub workflow runs (swift-format lint --strict + swiftlint lint --strict).
#
# Run from repo root:
#   bash scripts/fmt-lint.sh
#
# Exit codes:
#   0  -> clean (would pass GH workflow)
#   1  -> issues remain (would fail GH workflow)
#   2+ -> script/tooling/config errors

set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${ROOT_DIR}" ]]; then
  echo "ERROR: Not in a git repository."
  exit 2
fi

cd "${ROOT_DIR}"

SWIFT_FORMAT_CONFIG=".swift-format"
SWIFTLINT_CONFIG=".swiftlint.yml"

if [[ ! -f "${SWIFT_FORMAT_CONFIG}" ]]; then
  echo "ERROR: Missing ${SWIFT_FORMAT_CONFIG} in repo root."
  exit 2
fi

if [[ ! -f "${SWIFTLINT_CONFIG}" ]]; then
  echo "ERROR: Missing ${SWIFTLINT_CONFIG} in repo root."
  exit 2
fi

need_cmd() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "ERROR: '${cmd}' not found in PATH. Install it (e.g. brew install ${cmd})."
    exit 2
  fi
}

need_cmd swift-format
need_cmd swiftlint

echo "== Tool versions =="
echo "swift-format: $(swift-format --version 2>&1 || echo 'unknown')"
echo "swiftlint: $(swiftlint version 2>/dev/null || true)"
echo

# Gather Swift files the same way your GH workflow does
FILES="$(git ls-files '*.swift' || true)"
if [[ -z "${FILES}" ]]; then
  echo "No Swift files found."
  exit 0
fi

echo "== 1) Auto-correct: swift-format format =="
# Format tracked swift files deterministically using the repo config
# Use xargs safely for whitespace/newlines in filenames
printf "%s\n" "${FILES}" | tr '\n' '\0' | xargs -0 swift-format format \
  --configuration "${SWIFT_FORMAT_CONFIG}" \
  --

echo "== 2) Auto-correct: swiftlint fix (best-effort) =="
# SwiftLint fix doesn't support every rule; still useful.
# Explicitly point to the config to avoid surprises.
swiftlint fix --config "${SWIFTLINT_CONFIG}" || true

echo
echo "== 3) Checks (matches GH workflow) =="

echo "-- 3a) swift-format lint --strict --configuration .swift-format"
set +e
printf "%s\n" "${FILES}" | tr '\n' '\0' | xargs -0 swift-format lint \
  --strict \
  --configuration "${SWIFT_FORMAT_CONFIG}" \
  --
SWIFT_FORMAT_STATUS=$?
set -e

echo
echo "-- 3b) swiftlint lint --strict --reporter github-actions-logging"
set +e
swiftlint lint \
  --strict \
  --reporter github-actions-logging \
  --config "${SWIFTLINT_CONFIG}"
SWIFTLINT_STATUS=$?
set -e

echo
echo "== Summary =="

if [[ ${SWIFT_FORMAT_STATUS} -eq 0 ]]; then
  echo "swift-format: PASS"
else
  echo "swift-format: FAIL (exit ${SWIFT_FORMAT_STATUS})"
fi

if [[ ${SWIFTLINT_STATUS} -eq 0 ]]; then
  echo "swiftlint: PASS"
else
  echo "swiftlint: FAIL (exit ${SWIFTLINT_STATUS})"
fi

echo
if [[ ${SWIFT_FORMAT_STATUS} -eq 0 && ${SWIFTLINT_STATUS} -eq 0 ]]; then
  echo "Result: CLEAN (should pass the GH Lint workflow)."
  exit 0
else
  echo "Result: ISSUES REMAIN (would fail the GH Lint workflow)."
  echo
  echo "Tip: review changes and violations, then commit the formatter fixes."
  exit 1
fi
