#!/usr/bin/env bash
# telegram-diag.sh - one-shot probe for a silent Hermes Telegram bot.
# Prints PASS/FAIL for each stage. NEVER prints secret values.
set -uo pipefail
ENV="${HERMES_HOME:-$HOME/.hermes}/.env"
LOG="${HERMES_HOME:-$HOME/.hermes}/logs/gateway.log"
ERRLOG="${HERMES_HOME:-$HOME/.hermes}/logs/errors.log"

TOKEN=$(grep '^TELEGRAM_BOT_TOKEN=' "$ENV" | head -1 | cut -d= -f2- | tr -d '\n\r')
OR_KEY=$(grep '^OPENROUTER_API_KEY=' "$ENV" | head -1 | cut -d= -f2- | tr -d '\n\r' | sed 's/[[:space:]]*$//')

echo "== 1. Telegram token / getMe =="
curl -s "https://api.telegram.org/bot$TOKEN/getMe" | grep -q '"is_bot":true' && echo "PASS bot alive" || echo "FAIL token (401=wrong)"

echo "== 2. Webhook (must be empty) =="
curl -s "https://api.telegram.org/bot$TOKEN/getWebhookInfo" | grep -q '"url":""' && echo "PASS polling mode" || echo "WARN webhook set (may eat updates)"

echo "== 3. Gateway status =="
timeout 20 hermes gateway status 2>/dev/null | grep -q "process running" && echo "PASS gateway up" || echo "FAIL gateway down -> hermes gateway restart"

echo "== 4. Model provider in config =="
CFG="${HERMES_HOME:-$HOME/.hermes}/config.yaml"
grep -qE 'provider: (openrouter|nous)' "$CFG" && echo "PASS provider set" || echo "WARN provider not openrouter/nous (maybe github/copilot)"

echo "== 5. OpenRouter key live test =="
RESP=$(curl -s https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OR_KEY" -H "Content-Type: application/json" \
  -d '{"model":"qwen/qwen3-coder:free","messages":[{"role":"user","content":"reply only: OK"}]}')
if echo "$RESP" | grep -q '"choices"'; then echo "PASS model key works";
elif echo "$RESP" | grep -q '401'; then echo "FAIL wrong/stale OpenRouter key";
elif echo "$RESP" | grep -q '429'; then echo "WARN rate-limited (free model busy, retry)";
else echo "WARN unknown: ${RESP:0:120}"; fi

echo "== 6. errors.log tell-tale (GitHub PAT as AI key?) =="
grep -q "not supported by the Copilot API" "$ERRLOG" 2>/dev/null && echo "FAIL using GitHub PAT as AI key" || echo "PASS no PAT-as-AI-key error"

echo "== 7. Recent gateway activity =="
grep -iE 'telegram connected|inbound message|response ready' "$LOG" 2>/dev/null | tail -3 || echo "(no recent activity)"
