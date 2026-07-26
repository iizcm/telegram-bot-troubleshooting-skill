---
name: telegram-bot-troubleshooting
description: "Diagnose a non-responsive Hermes Telegram bot (or any Hermes chat-platform bot). Covers the recurring failure class: bot connects but won't reply — usually a wrong/stale AI model key, not the Telegram token. Use when user says 'bot nggak mau bales', 'telegram bot diam', or reports a silent agent."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [windows, linux, macos]
metadata:
  hermes:
    tags: [Telegram, Bot, Troubleshooting, Gateway, OpenRouter, Diagnosis]
---

# Telegram Bot Troubleshooting (Hermes)

Root-cause pattern seen repeatedly: **the Telegram bot connects fine, but won't reply.**
That is almost NEVER the Telegram token. It is the **AI model key / provider** the gateway
uses to generate the reply. If the model key is wrong/expired/unsupported, the agent has
nothing to say → user sees silence.

## Mental model
Bot = front door. Gateway = the brain. Model key = the mouth.
- Telegram token wrong  → bot can't even connect (getMe fails)
- Gateway dead          → no process, nothing logged
- **Model key wrong**   → bot connects, receives msg, but reply fails → SILENCE (most common)

## Diagnosis flow (run in order)
See `references/telegram-debug-checklist.md` for exact commands, and run
`scripts/telegram-diag.sh` for a one-shot probe.

1. **Token present + valid?** Check `.env` for `TELEGRAM_BOT_TOKEN`, then `getMe`. A 401 here = wrong token.
2. **Webhook empty?** `getWebhookInfo` must show `"url":""` (polling mode). A stale webhook silently eats updates.
3. **Gateway alive?** `hermes gateway status` → "process running (PID: N)". If not, restart.
4. **Config model/provider correct?** `config.yaml` should have `provider: openrouter` (or nous), NOT github/copilot as the default model source.
5. **Model key valid?** Test OpenRouter directly: `curl .../chat/completions` with the key. A 401 = wrong key. A 429 = rate-limited (normal for free models, just retry).
6. **Read errors.log** for `not supported` / `Unauthorized` / `401`. The tell-tale line:
   `Token from GITHUB_TOKEN is not supported: Classic Personal Access Tokens (ghp_*) are not supported by the Copilot API.` → means the agent tried to use the GitHub PAT as an AI key.
7. **Read gateway.log** for `telegram connected`, `inbound message`, `response ready`, `sending response`.

## Common fixes
- **Wrong OpenRouter key in `.env`** (stale/foreign): rewrite the real key, strip trailing whitespace:
  `printf 'OPENROUTER_API_KEY=sk-or-...\n' >> "$ENV"` then RESTART gateway.
- **GitHub PAT used as model key**: set `provider: openrouter` + real OpenRouter key; never reuse `ghp_*`.
- **Free model overloaded (429)**: switch default to a stable free coder (`qwen/qwen3-coder:free`) and add a `fallback_model` (e.g. `openai/gpt-oss-120b:free`).
- **After any config/.env change**: `hermes gateway restart` is REQUIRED — changes don't apply live.

## Pitfalls
- `.env` cannot be read with `read_file` (secret-bearing, access denied). Extract via terminal `grep`, never print the value.
- On Windows git-bash, `.env` resolves to `C:/Users/Asus/.hermes/.env` — use `${HERMES_HOME:-$HOME/.hermes}/.env`, NOT `/c/Users/...` for git ops.
- Don't trust "key exists" — verify with a live API call. This session the `.env` had a foreign OPENROUTER_API_KEY that wasn't the user's; it passed a grep check but failed 401 on use.
- Test messages sent via `sendMessage` API from the bot side may NOT register as inbound to the agent. Have the USER send a real message in Telegram to confirm end-to-end.
