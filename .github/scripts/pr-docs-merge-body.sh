#!/usr/bin/env bash
set -euo pipefail

: "${PR_DOCS_DIR:?PR_DOCS_DIR is required}"
: "${GITHUB_EVENT_PATH:?GITHUB_EVENT_PATH is required}"

START_MARKER="<!-- pr-docs:start -->"
END_MARKER="<!-- pr-docs:end -->"

EXISTING_BODY_FILE="$PR_DOCS_DIR/existing_body.md"
BLOCK_FILE="$PR_DOCS_DIR/generated_block.md"
SECTION_FILE="$PR_DOCS_DIR/generated_section.md"
FINAL_BODY_FILE="$PR_DOCS_DIR/final_pr_body.md"

if [[ ! -f "$BLOCK_FILE" ]]; then
  echo "::error::Missing generated PR block: $BLOCK_FILE"
  exit 1
fi

jq -r '.pull_request.body // ""' "$GITHUB_EVENT_PATH" > "$EXISTING_BODY_FILE"

{
  printf '%s\n' "$START_MARKER"
  cat "$BLOCK_FILE"
  printf '%s\n' "$END_MARKER"
} > "$SECTION_FILE"

if grep -Fxq "$START_MARKER" "$EXISTING_BODY_FILE" && grep -Fxq "$END_MARKER" "$EXISTING_BODY_FILE"; then
  awk -v start="$START_MARKER" -v end="$END_MARKER" -v section_file="$SECTION_FILE" '
    BEGIN {
      while ((getline line < section_file) > 0) {
        section = section line ORS
      }
      in_block = 0
    }
    {
      if ($0 == start) {
        printf "%s", section
        in_block = 1
        next
      }
      if ($0 == end) {
        in_block = 0
        next
      }
      if (!in_block) {
        print
      }
    }
  ' "$EXISTING_BODY_FILE" > "$FINAL_BODY_FILE"
else
  if grep -q '[^[:space:]]' "$EXISTING_BODY_FILE"; then
    cat "$EXISTING_BODY_FILE" > "$FINAL_BODY_FILE"
    printf '\n\n' >> "$FINAL_BODY_FILE"
  fi
  cat "$SECTION_FILE" >> "$FINAL_BODY_FILE"
fi

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  if cmp -s "$EXISTING_BODY_FILE" "$FINAL_BODY_FILE"; then
    echo "changed=false" >> "$GITHUB_OUTPUT"
  else
    echo "changed=true" >> "$GITHUB_OUTPUT"
  fi
fi

echo "Merged generated docs into PR body."
