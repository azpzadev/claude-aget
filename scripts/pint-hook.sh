#!/usr/bin/env bash
# PostToolUse hook — Claude ပြင်လိုက်တဲ့ .php ဖိုင်ကို သက်ဆိုင်ရာ project ရဲ့ Pint နဲ့ format လုပ်တယ်။
# Pint မရှိရင် တိတ်တိတ်ကျော်တယ် (hook က tool call ကို ဘယ်တော့မှ မပျက်စေရ)။
set -uo pipefail

payload=$(cat)
file=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || exit 0
[ -z "$file" ] && exit 0
case "$file" in
  *.php) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

dir=$(cd "$(dirname "$file")" 2>/dev/null && pwd) || exit 0
while [ "$dir" != "/" ] && [ -n "$dir" ]; do
  if [ -x "$dir/vendor/bin/pint" ]; then
    (cd "$dir" && ./vendor/bin/pint "$file" >/dev/null 2>&1) || true
    exit 0
  fi
  dir=$(dirname "$dir")
done
exit 0
