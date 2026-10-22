---
description: Clone လုပ်ပြီးသား repo ကို စစ်ပြီး CLAUDE.md, docs, .claude/ scaffold ဖြည့်ပေးတယ်
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

အခု project ကို Claude Code အတွက် setup လုပ်ပေးပါ။

## 1. စစ်ပါ

```bash
ls -a | head -40
cat composer.json 2>/dev/null | jq '{php: .require.php, laravel: .require["laravel/framework"], scripts: (.scripts|keys), dev: (.["require-dev"]|keys)}'
cat package.json 2>/dev/null | jq '{scripts, deps: (.dependencies|keys)}'
ls app 2>/dev/null; ls database/migrations 2>/dev/null | tail -5
grep -E '^(DB_CONNECTION|DB_DATABASE|APP_URL)' .env.example 2>/dev/null
git log --oneline -10
```

## 2. Scaffold

`~/workspace/scripts/new-project.sh --existing .` ကို run ပါ (idempotent — ရှိပြီးသားဖိုင် မထိဘူး)။

## 3. CLAUDE.md ဖြည့်ပါ

Scaffold ထည့်ထားတဲ့ placeholder တွေကို အပေါ်က စစ်လို့ရတဲ့ အချက်အလက်အစစ်နဲ့ အစားထိုးပါ။ စည်းကမ်း:

- `~/workspace/CLAUDE.md` မှာ ရှိပြီးသား default (Laravel 13, PHP 8.3+, Pest, Pint, PostgreSQL) ကို **ပြန်မရေးပါနဲ့** — ကွဲတာပဲ ရေးပါ။
- Command တွေကို `composer.json` ရဲ့ `scripts` ထဲက အစစ်ပဲ ရေးပါ — မှန်းမရေးပါနဲ့။
- ၅၀ လိုင်းအောက် ထားပါ။ ရှည်တာ `docs/architecture.md` ထဲ။
- Connection ၁ ခုထက်ပိုရင် ဘယ်ဟာ default, ဘယ်ဟာ read-only ဆိုတာ သေချာရေးပါ။

## 4. `~/workspace/PROJECTS.md`

ဒီ project ရဲ့ လိုင်းမှာ Stack နဲ့ Local URL ကို အစစ်အမှန်နဲ့ ဖြည့်ပါ။

## 5. အဆုံးသတ်

ဘာထည့်လိုက်လဲ၊ ဘာ assume လုပ်လိုက်လဲ၊ ကိုယ်တိုင် အတည်ပြုရမယ့်အချက် ဘာရှိလဲ — အတိုချုပ် ပြောပြပါ။
