#!/usr/bin/env bash
set -euo pipefail

: "${PR_DOCS_DIR:?PR_DOCS_DIR is required}"
: "${PR_NUMBER:?PR_NUMBER is required}"
: "${PR_ACTION:?PR_ACTION is required}"
: "${PR_BASE_REF:?PR_BASE_REF is required}"
: "${PR_HEAD_SHA:?PR_HEAD_SHA is required}"

mkdir -p "$PR_DOCS_DIR"

ZERO_SHA="0000000000000000000000000000000000000000"
HEAD_COMMIT="$PR_HEAD_SHA"
BASE_COMMIT="origin/$PR_BASE_REF"
PUSH_CONTEXT_AVAILABLE="false"

truncate_to_limits() {
  local input_file="$1"
  local output_file="$2"
  local max_lines="$3"
  local max_bytes="$4"

  if [[ ! -f "$input_file" ]]; then
    printf 'N/A\n' > "$output_file"
    return
  fi

  sed -n "1,${max_lines}p" "$input_file" | head -c "$max_bytes" > "$output_file"

  if [[ ! -s "$output_file" ]]; then
    printf 'N/A\n' > "$output_file"
  fi
}

ensure_non_empty() {
  local file="$1"
  if [[ ! -s "$file" ]]; then
    printf 'N/A\n' > "$file"
  fi
}

# Ensure base branch is present.
git fetch --no-tags --depth=200 origin "$PR_BASE_REF"

# Ensure PR head commit is present.
if ! git cat-file -e "$HEAD_COMMIT^{commit}" 2>/dev/null; then
  git fetch --no-tags --depth=50 origin "$HEAD_COMMIT" || true
fi
if ! git cat-file -e "$HEAD_COMMIT^{commit}" 2>/dev/null; then
  git fetch --no-tags --depth=50 origin "refs/pull/${PR_NUMBER}/head:refs/remotes/origin/pr/${PR_NUMBER}" || true
  if git cat-file -e "origin/pr/${PR_NUMBER}^{commit}" 2>/dev/null; then
    HEAD_COMMIT="origin/pr/${PR_NUMBER}"
  fi
fi

if ! git cat-file -e "$HEAD_COMMIT^{commit}" 2>/dev/null; then
  echo "::error::Unable to resolve PR head commit for #${PR_NUMBER}."
  exit 1
fi

if ! git cat-file -e "$BASE_COMMIT^{commit}" 2>/dev/null; then
  echo "::error::Unable to resolve base branch commit for ${PR_BASE_REF}."
  exit 1
fi

HEAD_SHORT="$(git rev-parse --short=7 "$HEAD_COMMIT")"

# Full PR context (base...head)
git diff --shortstat "$BASE_COMMIT...$HEAD_COMMIT" > "$PR_DOCS_DIR/full_shortstat.txt" || true
git diff --stat=120 "$BASE_COMMIT...$HEAD_COMMIT" > "$PR_DOCS_DIR/full_diff_stat_raw.txt" || true
git log --no-merges --pretty='- %h %s' "$BASE_COMMIT..$HEAD_COMMIT" > "$PR_DOCS_DIR/full_commits_raw.txt" || true
git diff --name-status "$BASE_COMMIT...$HEAD_COMMIT" > "$PR_DOCS_DIR/full_name_status_raw.txt" || true
git diff "$BASE_COMMIT...$HEAD_COMMIT" -- \
  '*.swift' '*.md' '*.yml' '*.yaml' '*.json' '*.plist' '*.xcodeproj/project.pbxproj' \
  > "$PR_DOCS_DIR/full_diff_patch_raw.txt" || true

truncate_to_limits "$PR_DOCS_DIR/full_diff_stat_raw.txt" "$PR_DOCS_DIR/full_diff_stat.txt" 90 6000
truncate_to_limits "$PR_DOCS_DIR/full_commits_raw.txt" "$PR_DOCS_DIR/full_commits.txt" 40 2800
truncate_to_limits "$PR_DOCS_DIR/full_name_status_raw.txt" "$PR_DOCS_DIR/full_name_status.txt" 90 5000
truncate_to_limits "$PR_DOCS_DIR/full_diff_patch_raw.txt" "$PR_DOCS_DIR/full_diff_patch.txt" 80 5500

rm -f \
  "$PR_DOCS_DIR/full_diff_stat_raw.txt" \
  "$PR_DOCS_DIR/full_commits_raw.txt" \
  "$PR_DOCS_DIR/full_name_status_raw.txt" \
  "$PR_DOCS_DIR/full_diff_patch_raw.txt"

ensure_non_empty "$PR_DOCS_DIR/full_shortstat.txt"

# Push delta context (before..head)
printf 'N/A\n' > "$PR_DOCS_DIR/push_shortstat.txt"
printf 'N/A\n' > "$PR_DOCS_DIR/push_diff_stat.txt"
printf 'N/A\n' > "$PR_DOCS_DIR/push_commits.txt"
printf 'N/A\n' > "$PR_DOCS_DIR/push_name_status.txt"
printf 'N/A\n' > "$PR_DOCS_DIR/push_diff_patch.txt"

if [[ "$PR_ACTION" == "synchronize" && -n "${PR_BEFORE_SHA:-}" && "$PR_BEFORE_SHA" != "$ZERO_SHA" ]]; then
  if ! git cat-file -e "${PR_BEFORE_SHA}^{commit}" 2>/dev/null; then
    git fetch --no-tags --depth=50 origin "$PR_BEFORE_SHA" || true
  fi

  if git cat-file -e "${PR_BEFORE_SHA}^{commit}" 2>/dev/null; then
    PUSH_CONTEXT_AVAILABLE="true"

    git diff --shortstat "${PR_BEFORE_SHA}..$HEAD_COMMIT" > "$PR_DOCS_DIR/push_shortstat.txt" || true
    git diff --stat=120 "${PR_BEFORE_SHA}..$HEAD_COMMIT" > "$PR_DOCS_DIR/push_diff_stat_raw.txt" || true
    git log --no-merges --pretty='- %h %s' "${PR_BEFORE_SHA}..$HEAD_COMMIT" > "$PR_DOCS_DIR/push_commits_raw.txt" || true
    git diff --name-status "${PR_BEFORE_SHA}..$HEAD_COMMIT" > "$PR_DOCS_DIR/push_name_status_raw.txt" || true
    git diff "${PR_BEFORE_SHA}..$HEAD_COMMIT" -- \
      '*.swift' '*.md' '*.yml' '*.yaml' '*.json' '*.plist' '*.xcodeproj/project.pbxproj' \
      > "$PR_DOCS_DIR/push_diff_patch_raw.txt" || true

    truncate_to_limits "$PR_DOCS_DIR/push_diff_stat_raw.txt" "$PR_DOCS_DIR/push_diff_stat.txt" 70 4200
    truncate_to_limits "$PR_DOCS_DIR/push_commits_raw.txt" "$PR_DOCS_DIR/push_commits.txt" 20 1800
    truncate_to_limits "$PR_DOCS_DIR/push_name_status_raw.txt" "$PR_DOCS_DIR/push_name_status.txt" 70 3500
    truncate_to_limits "$PR_DOCS_DIR/push_diff_patch_raw.txt" "$PR_DOCS_DIR/push_diff_patch.txt" 100 8000

    rm -f \
      "$PR_DOCS_DIR/push_diff_stat_raw.txt" \
      "$PR_DOCS_DIR/push_commits_raw.txt" \
      "$PR_DOCS_DIR/push_name_status_raw.txt" \
      "$PR_DOCS_DIR/push_diff_patch_raw.txt"

    ensure_non_empty "$PR_DOCS_DIR/push_shortstat.txt"
  fi
fi

jq -n \
  --arg pr_number "$PR_NUMBER" \
  --arg action "$PR_ACTION" \
  --arg base_ref "$PR_BASE_REF" \
  --arg head_commit "$HEAD_COMMIT" \
  --arg head_short "$HEAD_SHORT" \
  --arg merged "${PR_MERGED:-false}" \
  --arg title "${PR_TITLE:-}" \
  --arg push_context "$PUSH_CONTEXT_AVAILABLE" \
  '{
    pr_number: ($pr_number | tonumber),
    action: $action,
    base_ref: $base_ref,
    head_commit: $head_commit,
    head_short: $head_short,
    merged: ($merged == "true"),
    title: $title,
    push_context_available: ($push_context == "true")
  }' > "$PR_DOCS_DIR/context.json"

echo "Collected PR context in: $PR_DOCS_DIR"
