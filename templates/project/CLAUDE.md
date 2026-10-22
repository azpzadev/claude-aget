# CLAUDE.md — {{PROJECT}}

Fleet-level convention တွေက `~/workspace/CLAUDE.md` မှာ ရှိတယ်။ ဒီဖိုင်မှာ **အဲ့ဒါနဲ့ ကွဲတဲ့အချက်ပဲ** ရေးပါ။
ရှည်တဲ့အရာတွေ `docs/` ထဲထည့်ပြီး ဒီကနေ link ပေးပါ။ ဒီဖိုင် ၅၀ လိုင်းအောက် ထားပါ။

## ဘာလုပ်တဲ့ project လဲ

<!-- ၂-၃ လိုင်း။ ဘယ်သူသုံးလဲ၊ ဘာကိုဖြေရှင်းလဲ -->

## Stack (fleet default နဲ့ ကွဲတာပဲ)

<!-- ဥပမာ: Laravel 12 (13 မဟုတ်)၊ PHPUnit (Pest မဟုတ်)၊ MySQL (Postgres မဟုတ်) -->
- Laravel — 
- DB — 
- Test — 

## Commands

```bash
composer setup          # ပထမဆုံး setup
composer dev            # local dev stack
composer test           # test အကုန်
./vendor/bin/pint --dirty   # ပြင်ထားတဲ့ဖိုင် format
```

## Database / connections

<!-- connection ၁ ခုထက်ပိုရင် ဘယ်ဟာက ဘာအတွက်၊ ဘယ်ဟာက read-only လဲ ရေးပါ -->

## Architecture

<!-- ဖတ်သင့်တဲ့ entry point ၃-၄ ခုပဲ ပြပါ -->
- Routes — `routes/`
- Domain — `app/`
- အခြား — `docs/architecture.md`

## ဒီ project သီးသန့် တားမြစ်ချက်

<!-- ဥပမာ: supabase connection ပေါ် migration မ run ရ -->

## Docs

- `docs/architecture.md` — system အပြင်အဆင်
- `docs/decisions/` — ADR (ဘာကြောင့် ဒီလိုဆုံးဖြတ်လဲ)
- `docs/runbooks/` — deploy, migration, incident
