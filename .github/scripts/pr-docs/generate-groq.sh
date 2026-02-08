#!/usr/bin/env bash
set -euo pipefail

: "${PR_DOCS_DIR:?PR_DOCS_DIR is required}"
: "${GROQ_API_KEY:?GROQ_API_KEY is required}"
: "${DOCS_MODE:?DOCS_MODE is required}"

MODEL="${GROQ_MODEL:-groq/compound}"
API_URL="${GROQ_API_URL:-https://api.groq.com/openai/v1/chat/completions}"
MAX_PAYLOAD_BYTES="${MAX_GROQ_PAYLOAD_BYTES:-45000}"
CONTEXT_JSON="$PR_DOCS_DIR/context.json"

if [[ ! -f "$CONTEXT_JSON" ]]; then
  echo "::error::Missing context file: $CONTEXT_JSON"
  exit 1
fi

ACTION="$(jq -r '.action' "$CONTEXT_JSON")"
PUSH_CONTEXT_AVAILABLE="$(jq -r '.push_context_available' "$CONTEXT_JSON")"
MERGED="$(jq -r '.merged' "$CONTEXT_JSON")"
HEAD_SHORT="$(jq -r '.head_short // "unknown"' "$CONTEXT_JSON")"

FULL_SHORTSTAT="$(cat "$PR_DOCS_DIR/full_shortstat.txt")"
FULL_DIFF_STAT="$(cat "$PR_DOCS_DIR/full_diff_stat.txt")"
FULL_COMMITS="$(cat "$PR_DOCS_DIR/full_commits.txt")"
FULL_NAME_STATUS="$(cat "$PR_DOCS_DIR/full_name_status.txt")"
FULL_PATCH="$(cat "$PR_DOCS_DIR/full_diff_patch.txt")"

PUSH_SHORTSTAT="$(cat "$PR_DOCS_DIR/push_shortstat.txt")"
PUSH_DIFF_STAT="$(cat "$PR_DOCS_DIR/push_diff_stat.txt")"
PUSH_COMMITS="$(cat "$PR_DOCS_DIR/push_commits.txt")"
PUSH_NAME_STATUS="$(cat "$PR_DOCS_DIR/push_name_status.txt")"
PUSH_PATCH="$(cat "$PR_DOCS_DIR/push_diff_patch.txt")"

# Hard-cap oversized fields to avoid context blowup.
FULL_SHORTSTAT="${FULL_SHORTSTAT:0:260}"
FULL_DIFF_STAT="${FULL_DIFF_STAT:0:5500}"
FULL_COMMITS="${FULL_COMMITS:0:2500}"
FULL_NAME_STATUS="${FULL_NAME_STATUS:0:4200}"
FULL_PATCH="${FULL_PATCH:0:4500}"
PUSH_SHORTSTAT="${PUSH_SHORTSTAT:0:260}"
PUSH_DIFF_STAT="${PUSH_DIFF_STAT:0:3800}"
PUSH_COMMITS="${PUSH_COMMITS:0:1600}"
PUSH_NAME_STATUS="${PUSH_NAME_STATUS:0:3000}"
PUSH_PATCH="${PUSH_PATCH:0:5000}"

SYSTEM_PROMPT=""
USER_CONTEXT=""
USER_CHAR_LIMIT=""
MAX_TOKENS=""

if [[ "$DOCS_MODE" == "body" ]]; then
  SYSTEM_PROMPT="You write high-signal PR notes for senior engineers. Return markdown bullets only. No headings. No fluff. No generic language. No code fences."
  USER_CHAR_LIMIT="22000"
  MAX_TOKENS="520"
  USER_CONTEXT="$(cat <<EOF_BODY
Task: Generate a body note for a pull request event.

Hard requirements:
- Output 6-12 markdown bullets only.
- First bullet is one-line summary of what this PR is doing.
- Include event state explicitly: action=$ACTION merged=$MERGED.
- Mention net diff briefly using the shortstat.
- Mention key changed areas from files/commits.
- Mention risk/check bullets only when supported by the provided context.
- No section headings.
- No words like "overview", "at a glance", "summary".

Context:
PR metadata: $(cat "$CONTEXT_JSON")
Full shortstat:
$FULL_SHORTSTAT
Full diff stat:
$FULL_DIFF_STAT
Full commits:
$FULL_COMMITS
Full changed files:
$FULL_NAME_STATUS
Small patch sample:
$FULL_PATCH
EOF_BODY
)"
elif [[ "$DOCS_MODE" == "push_comment" ]]; then
  SYSTEM_PROMPT="You write push-update notes for senior engineers. Return markdown bullets only. No headings. No fluff. No code fences."
  USER_CHAR_LIMIT="14000"
  MAX_TOKENS="360"
  USER_CONTEXT="$(cat <<EOF_PUSH
Task: Generate a comment for the latest push to this PR.

Hard requirements:
- Output 4-10 markdown bullets only.
- Describe only what changed in this push delta.
- Do not describe previous PR history.
- First bullet starts exactly with: - Push $HEAD_SHORT
- If push delta is unavailable, output exactly: - Push delta unavailable for this event.
- No section headings.
- No words like "overview", "at a glance", "summary".

Context:
PR metadata: $(cat "$CONTEXT_JSON")
push_context_available=$PUSH_CONTEXT_AVAILABLE
Push shortstat:
$PUSH_SHORTSTAT
Push diff stat:
$PUSH_DIFF_STAT
Push commits:
$PUSH_COMMITS
Push changed files:
$PUSH_NAME_STATUS
Push patch sample:
$PUSH_PATCH
EOF_PUSH
)"
else
  echo "::error::Unsupported DOCS_MODE: $DOCS_MODE"
  exit 1
fi

USER_CONTEXT="${USER_CONTEXT:0:$USER_CHAR_LIMIT}"

build_payload() {
  local trimmed_context="$1"
  jq -n \
    --arg model "$MODEL" \
    --arg system "$SYSTEM_PROMPT" \
    --arg user "$trimmed_context" \
    --argjson max_tokens "$MAX_TOKENS" \
    '{
      model: $model,
      messages: [
        {role: "system", content: $system},
        {role: "user", content: $user}
      ],
      temperature: 0.1,
      max_tokens: $max_tokens
    }'
}

trim_limit="$USER_CHAR_LIMIT"
PAYLOAD=""
PAYLOAD_BYTES=0

while true; do
  trimmed_context="${USER_CONTEXT:0:$trim_limit}"
  PAYLOAD="$(build_payload "$trimmed_context")"
  PAYLOAD_BYTES="$(printf '%s' "$PAYLOAD" | wc -c | tr -d ' ')"

  if (( PAYLOAD_BYTES <= MAX_PAYLOAD_BYTES )) || (( trim_limit <= 1200 )); then
    break
  fi

  trim_limit=$((trim_limit * 3 / 4))
done

RESPONSE_FILE="$PR_DOCS_DIR/groq_response.json"
HTTP_CODE="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  "$API_URL" \
  -H "Authorization: Bearer ${GROQ_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")"

BODY="$(jq -r '.choices[0].message.content // empty' "$RESPONSE_FILE")"
ERROR_MESSAGE="$(jq -r '.error.message // empty' "$RESPONSE_FILE")"
ERROR_TYPE="$(jq -r '.error.type // empty' "$RESPONSE_FILE")"

if [[ -n "${BODY//[[:space:]]/}" ]]; then
  {
    printf '%s\n\n' "$BODY"
    printf -- '---\n_Autogenerated by Groq %s._\n' "$MODEL"
  } > "$PR_DOCS_DIR/generated_block.md"
  echo "Groq docs generated."
  exit 0
fi

recoverable_error="false"
if [[ "$HTTP_CODE" == "429" ]]; then
  recoverable_error="true"
fi
if echo "$ERROR_MESSAGE" | grep -Eiq 'rate.?limit|quota|too many requests|usage limit|resource exhausted|context length|prompt too long|request too large|token|model.+(not found|does not exist|unavailable)'; then
  recoverable_error="true"
fi

if [[ "$recoverable_error" == "true" ]]; then
  echo "Groq recoverable failure (${HTTP_CODE}/${ERROR_TYPE}): ${ERROR_MESSAGE}" >&2
  exit 42
fi

echo "::error::Groq generation failed (HTTP ${HTTP_CODE}, type ${ERROR_TYPE})."
if [[ -n "$ERROR_MESSAGE" ]]; then
  echo "::error::${ERROR_MESSAGE}"
fi
exit 1
