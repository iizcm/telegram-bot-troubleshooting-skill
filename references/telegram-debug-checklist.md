# Telegram Bot Debug Checklist (exact commands)

Env:
```
ENV="${HERMES_HOME:-$HOME/.hermes}/.env"
CFG="${HERMES_HOME:-$HOME/.hermes}/config.yaml"
LOG="${HERMES_HOME:-$HOME/.hermes}/logs/gateway.log"
ERRLOG="${HERMES_HOME:-$HOME/.hermes}/logs/errors.log"
```
NOTE: `.env` cannot be read with `read_file` (secret-bearing). Extract via terminal, NEVER print the value:
```
TOKEN=$(grep '^TELEGRAM_BOT_TOKEN=' "$ENV" | head -1 | cut -d= -f2- | tr -d '\n\r')
OR_KEY=$(grep '^OPENROUTER_API_KEY=' "$ENV" | head -1 | cut -d= -f2- | tr -d '\n\r' | sed 's/[[:space:]]*$//')
```

## 1. Token valid?
```
curl -s "https://api.telegram.org/bot$TOKEN/getMe" | head -c 200
# expect {"ok":true,"result":{"is_bot":true,...}}
# 401 = wrong token
```

## 2. Webhook empty? (must be "" for polling)
```
curl -s "https://api.telegram.org/bot$TOKEN/getWebhookInfo" | head -c 200
# expect "url":""
```

## 3. Gateway alive?
```
timeout 20 hermes gateway status
# expect "Gateway process running (PID: N)"
```

## 4. Config model provider
```
sed -n '1,4p' "$CFG"
# expect: model: / default: <model> / provider: openrouter
grep -niE 'provider|default:' "$CFG" | head
```

## 5. Model key valid? (THE usual culprit)
```
RESP=$(curl -s https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen/qwen3-coder:free","messages":[{"role":"user","content":"reply only: OK"}]}')
echo "$RESP" | head -c 300
# 401 Missing Authentication header  = WRONG/STALE KEY
# 429 rate-limited              = free model busy, retry (normal)
# {"choices":...}              = OK
```

## 6. errors.log tell-tale
```
grep -iE 'not supported|Unauthorized|401|copilot' "$ERRLOG" | tail -10
# "Token from GITHUB_TOKEN is not supported: Classic Personal Access Tokens (ghp_*) are not supported by the Copilot API"
#   => agent tried to use GitHub PAT as AI key. Fix: set provider openrouter + real OpenRouter key.
```

## 7. gateway.log flow
```
grep -iE 'telegram connected|inbound message|response ready|sending response' "$LOG" | tail -8
```

## Fix & restart (required after .env/config change)
```
# rewrite correct key (strip trailing whitespace)
printf 'OPENROUTER_API_KEY=sk-or-REALKEY\n' >> "$ENV"
timeout 30 hermes gateway restart
sleep 8
timeout 20 hermes gateway status
```
Then ask the USER to send a real Telegram message (API-side sendMessage may NOT register as inbound).
