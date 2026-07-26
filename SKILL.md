---
name: telegram-bot-troubleshooting
description: "Diagnose a non-responsive Hermes Telegram bot (or any Hermes chat-platform bot). Covers the recurring failure class: bot connects but won't reply — usually a wrong/stale AI model key, not the Telegram token. Use when user says 'bot nggak mau bales', 'telegram bot diam', or reports a silent agent."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [windows, linux, macos]
tags: [general]
---

# Telegram Bot Troubleshooting — Skill

Diagnose a non-responsive Hermes Telegram bot (or any Hermes chat-platform bot). Covers the recurring failure class: bot connects but won't reply — usually a wrong/stale AI model key, not the Telegram token. Use when user says 'bot nggak mau bales', 'telegram bot diam', or reports a silent agent.

## Install

```bash
cp -r <skill-name> ~/.hermes/skills/<skill-path>/
```

Or clone this repository:

```bash
git clone https://github.com/iizcm/telegram-bot-troubleshooting-skill.git ~/.hermes/skills/<skill-path>/
```

## Usage

Invoke your AI agent with a clear instruction matching this skill's purpose. The agent will route tasks to this skill when the instruction matches its description or trigger keywords.

Refer to `README.md` in this repository for:
- Detailed step-by-step installation guide
- Bilingual documentation (English + Indonesian)
- Troubleshooting table
- Security best practices
- Customization tips

## Safety rules

- Never commit private keys, seed phrases, API tokens, or personal data to version control
- Use placeholders (`<YOUR_...>`) in all examples and code snippets
- Validate all outputs before acting on them
- Keep real credentials in your runtime's secure credential store only
