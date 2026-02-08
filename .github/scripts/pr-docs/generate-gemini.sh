#!/usr/bin/env bash
set -euo pipefail

: "${PR_DOCS_DIR:?PR_DOCS_DIR is required}"
: "${GEMINI_API_KEY:?GEMINI_API_KEY is required}"

MODEL="${GEMINI_MODEL:-gemini-2.0-flash}"
CONTEXT_JSON="$PR_DOCS_DIR/context.json"

if [[ ! -f "$CONTEXT_JSON" ]]; then
  echo "::error::Missing context file: $CONTEXT_JSON"
  exit 1
fi

ACTION="$(jq -r '.action' "$CONTEXT_JSON")"
PUSH_CONTEXT_AVAILABLE="$(jq -r '.push_context_available' "$CONTEXT_JSON")"
MERGED="$(jq -r '.merged' "$CONTEXT_JSON")"

FOCUS_SHORTSTAT_FILE="$PR_DOCS_DIR/full_shortstat.txt"
FOCUS_DIFF_STAT_FILE="$PR_DOCS_DIR/full_diff_stat.txt"
FOCUS_COMMITS_FILE="$PR_DOCS_DIR/full_commits.txt"
FOCUS_NAME_STATUS_FILE="$PR_DOCS_DIR/full_name_status.txt"
FOCUS_PATCH_FILE="$PR_DOCS_DIR/full_diff_patch.txt"
FOCUS_SCOPE="full_pr"

if [[ "$ACTION" == "synchronize" && "$PUSH_CONTEXT_AVAILABLE" == "true" ]]; then
  FOCUS_SHORTSTAT_FILE="$PR_DOCS_DIR/push_shortstat.txt"
  FOCUS_DIFF_STAT_FILE="$PR_DOCS_DIR/push_diff_stat.txt"
  FOCUS_COMMITS_FILE="$PR_DOCS_DIR/push_commits.txt"
  FOCUS_NAME_STATUS_FILE="$PR_DOCS_DIR/push_name_status.txt"
  FOCUS_PATCH_FILE="$PR_DOCS_DIR/push_diff_patch.txt"
  FOCUS_SCOPE="this_push"
fi

FOCUS_SHORTSTAT="N/A"
FOCUS_DIFF_STAT="N/A"
FOCUS_COMMITS="N/A"
FOCUS_NAME_STATUS="N/A"
FOCUS_PATCH="N/A"

if [[ "$FOCUS_SCOPE" == "this_push" ]]; then
  FOCUS_SHORTSTAT="$(cat "$FOCUS_SHORTSTAT_FILE")"
  FOCUS_DIFF_STAT="$(cat "$FOCUS_DIFF_STAT_FILE")"
  FOCUS_COMMITS="$(cat "$FOCUS_COMMITS_FILE")"
  FOCUS_NAME_STATUS="$(cat "$FOCUS_NAME_STATUS_FILE")"
  FOCUS_PATCH="$(cat "$FOCUS_PATCH_FILE")"
fi

FULL_SHORTSTAT="$(cat "$PR_DOCS_DIR/full_shortstat.txt")"
FULL_DIFF_STAT="$(cat "$PR_DOCS_DIR/full_diff_stat.txt")"
FULL_COMMITS="$(cat "$PR_DOCS_DIR/full_commits.txt")"
FULL_NAME_STATUS="$(cat "$PR_DOCS_DIR/full_name_status.txt")"

FULL_SHORTSTAT="${FULL_SHORTSTAT:0:300}"
FULL_DIFF_STAT="${FULL_DIFF_STAT:0:12000}"
FULL_COMMITS="${FULL_COMMITS:0:9000}"
FULL_NAME_STATUS="${FULL_NAME_STATUS:0:10000}"
FOCUS_SHORTSTAT="${FOCUS_SHORTSTAT:0:300}"
FOCUS_DIFF_STAT="${FOCUS_DIFF_STAT:0:8000}"
FOCUS_COMMITS="${FOCUS_COMMITS:0:4500}"
FOCUS_NAME_STATUS="${FOCUS_NAME_STATUS:0:6500}"
FOCUS_PATCH="${FOCUS_PATCH:0:15000}"

PROMPT="$(cat <<'PROMPT_EOF'
You write PR documentation for engineers.

Output markdown only.
Use direct, factual language.
No filler, no hype, no disclaimers, no code fences.

Required format:
## At a Glance
- 2-4 bullets with highest-impact changes and intent.

## This Push
- If action is synchronize and push_context_available is true, summarize only this push delta.
- Otherwise output exactly: - No incremental push delta for this event.

## Key Changes
- Group concrete changes by area.
- Each bullet should state what changed and why it matters.

## Verification
- 1-3 bullets with available validation evidence.
- If evidence is missing, output exactly: - Verification evidence is not present in commits/diff.

Rules:
- 110-220 words total.
- Mention user-visible behavior when inferable.
- If action is closed, explicitly say merged or not merged.
PROMPT_EOF
)"

build_payload() {
  jq -n \
    --arg prompt "$PROMPT" \
    --argjson meta "$(cat "$CONTEXT_JSON")" \
    --arg action "$ACTION" \
    --arg merged "$MERGED" \
    --arg push_context_available "$PUSH_CONTEXT_AVAILABLE" \
    --arg focus_scope "$FOCUS_SCOPE" \
    --arg full_shortstat "$FULL_SHORTSTAT" \
    --arg full_diff_stat "$FULL_DIFF_STAT" \
    --arg full_commits "$FULL_COMMITS" \
    --arg full_name_status "$FULL_NAME_STATUS" \
    --arg focus_shortstat "$FOCUS_SHORTSTAT" \
    --arg focus_diff_stat "$FOCUS_DIFF_STAT" \
    --arg focus_commits "$FOCUS_COMMITS" \
    --arg focus_name_status "$FOCUS_NAME_STATUS" \
    --arg focus_patch "$FOCUS_PATCH" \
    '{
      contents: [{
        parts: [{
          text: (
            $prompt
            + "\n\n--- EVENT META ---\n"
            + "action=" + $action + ", merged=" + $merged + ", push_context_available=" + $push_context_available + ", focus_scope=" + $focus_scope
            + "\n\n--- META JSON ---\n" + ($meta | tostring)
            + "\n\n--- FULL PR SHORTSTAT ---\n" + $full_shortstat
            + "\n\n--- FULL PR DIFF STAT (TRUNCATED) ---\n" + $full_diff_stat
            + "\n\n--- FULL PR COMMITS (TRUNCATED) ---\n" + $full_commits
            + "\n\n--- FULL PR CHANGED FILES ---\n" + $full_name_status
            + "\n\n--- FOCUS SHORTSTAT ---\n" + $focus_shortstat
            + "\n\n--- FOCUS DIFF STAT ---\n" + $focus_diff_stat
            + "\n\n--- FOCUS COMMITS ---\n" + $focus_commits
            + "\n\n--- FOCUS CHANGED FILES ---\n" + $focus_name_status
            + "\n\n--- FOCUS PATCH (HEAVILY TRUNCATED) ---\n" + $focus_patch
          )
        }]
      }],
      generationConfig: {
        temperature: 0.1,
        topP: 0.9,
        maxOutputTokens: 420
      }
    }'
}

CONTEXT_PAYLOAD="$(build_payload)"
MAX_PAYLOAD_BYTES="${MAX_GEMINI_PAYLOAD_BYTES:-90000}"
PAYLOAD_BYTES="$(printf '%s' "$CONTEXT_PAYLOAD" | wc -c | tr -d ' ')"

if (( PAYLOAD_BYTES > MAX_PAYLOAD_BYTES )); then
  # Drop patch context first; keep compact metadata and stats.
  FOCUS_PATCH="N/A (omitted due payload size limit)"
  CONTEXT_PAYLOAD="$(build_payload)"
  PAYLOAD_BYTES="$(printf '%s' "$CONTEXT_PAYLOAD" | wc -c | tr -d ' ')"
fi

if (( PAYLOAD_BYTES > MAX_PAYLOAD_BYTES )); then
  # If still too large, compact long sections further.
  FULL_DIFF_STAT="${FULL_DIFF_STAT:0:4000}"
  FULL_COMMITS="${FULL_COMMITS:0:2500}"
  FULL_NAME_STATUS="${FULL_NAME_STATUS:0:3000}"
  FOCUS_DIFF_STAT="${FOCUS_DIFF_STAT:0:3000}"
  FOCUS_COMMITS="${FOCUS_COMMITS:0:1800}"
  FOCUS_NAME_STATUS="${FOCUS_NAME_STATUS:0:2200}"
  CONTEXT_PAYLOAD="$(build_payload)"
  PAYLOAD_BYTES="$(printf '%s' "$CONTEXT_PAYLOAD" | wc -c | tr -d ' ')"
fi

if (( PAYLOAD_BYTES > MAX_PAYLOAD_BYTES )); then
  # Last-resort compact mode to avoid oversized requests.
  FULL_DIFF_STAT="N/A (trimmed for payload size)"
  FULL_COMMITS="N/A (trimmed for payload size)"
  FULL_NAME_STATUS="N/A (trimmed for payload size)"
  FOCUS_DIFF_STAT="N/A (trimmed for payload size)"
  FOCUS_COMMITS="N/A (trimmed for payload size)"
  FOCUS_NAME_STATUS="N/A (trimmed for payload size)"
  FOCUS_PATCH="N/A (trimmed for payload size)"
  CONTEXT_PAYLOAD="$(build_payload)"
fi

RESPONSE_FILE="$PR_DOCS_DIR/gemini_response.json"
HTTP_CODE="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$CONTEXT_PAYLOAD")"

BODY="$(jq -r '.candidates[0].content.parts[0].text // empty' "$RESPONSE_FILE")"
ERROR_STATUS="$(jq -r '.error.status // empty' "$RESPONSE_FILE")"
ERROR_MESSAGE="$(jq -r '.error.message // empty' "$RESPONSE_FILE")"

if [[ -n "${BODY//[[:space:]]/}" ]]; then
  {
    printf '%s\n\n' "$BODY"
    printf -- '---\n_Autogenerated by Gemini %s._\n' "$MODEL"
  } > "$PR_DOCS_DIR/generated_block.md"
  echo "Gemini PR docs generated."
  exit 0
fi

is_usage_limit_error="false"
if [[ "$HTTP_CODE" == "429" || "$ERROR_STATUS" == "RESOURCE_EXHAUSTED" ]]; then
  is_usage_limit_error="true"
fi
if echo "$ERROR_MESSAGE" | grep -Eiq 'usage|quota|rate.?limit|resource.?exhausted|too many requests'; then
  is_usage_limit_error="true"
fi

if [[ "$is_usage_limit_error" == "true" ]]; then
  echo "Gemini usage limit hit (${HTTP_CODE}/${ERROR_STATUS})." >&2
  exit 42
fi

echo "::error::Gemini generation failed (HTTP ${HTTP_CODE}, status ${ERROR_STATUS})."
if [[ -n "$ERROR_MESSAGE" ]]; then
  echo "::error::${ERROR_MESSAGE}"
fi
exit 1
