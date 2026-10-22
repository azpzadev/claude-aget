# {{PRODUCT}} — repo map

Product တစ်ခုမှာ repo တွေခွဲထားတဲ့အခါ **ဒီဖိုင်က အရေးကြီးဆုံး**။
AI က session စတိုင်း ဒီဖိုင်ကို ဖတ်ပြီး "ဘယ်ဟာက ဘာလုပ်လဲ၊ ဘယ်ဟာကို ပြင်ရမလဲ" ဆိုတာ သိတယ်။
Repo တစ်ခု ထပ်ထည့်တိုင်း ဒီ table မှာ လိုင်းထည့်ပါ။

## Repos

| Repo | Role | Path | Local URL | Deploy |
|---|---|---|---|---|
| {{PRODUCT}}-api | Laravel HTTP API — business logic + DB ပိုင်ရှင် | `./{{PRODUCT}}-api` | https://{{PRODUCT}}-api.test | |
| {{PRODUCT}}-gateway | Edge / middleware — auth, routing, rate limit | `./{{PRODUCT}}-gateway` | https://{{PRODUCT}}-gateway.test | |
| {{PRODUCT}}-web | Nuxt frontend | `./{{PRODUCT}}-web` | http://localhost:3000 | |

## Request လမ်းကြောင်း

```
browser → {{PRODUCT}}-web → {{PRODUCT}}-gateway → {{PRODUCT}}-api → PostgreSQL
```

<!-- queue, cache, external service ရှိရင် ဒီမှာ ထည့်ပါ -->

## ပိုင်ရှင် သတ်မှတ်ချက် (boundary — ဒါက AI လွဲတာ အများဆုံး တားတယ်)

| အကြောင်းအရာ | ပိုင်ရှင် | တားမြစ် |
|---|---|---|
| DB schema / migration | `{{PRODUCT}}-api` | တခြား repo မှာ migration မရေးရ |
| Auth token ထုတ်တာ | `{{PRODUCT}}-gateway` | `-web` မှာ token logic မရေးရ |
| Business rule | `{{PRODUCT}}-api` | `-web`/`-gateway` မှာ ပြန်မရေးရ (validation ထပ်တာ ရတယ်) |
| UI / state | `{{PRODUCT}}-web` | `-api` မှာ view/blade မရှိရ |

## API contract — အမှန်တရား တစ်ခုတည်း

- Source of truth → `{{PRODUCT}}-api/docs/api/openapi.yaml`
- Endpoint တစ်ခု ပြောင်းရင် **အဲ့ဒီဖိုင် အရင်ပြင်**၊ ပြီးမှ `-api` နဲ့ `-web` ကို လိုက်ပြင်။
- Response shape ကို **ဘယ်တော့မှ မှန်းမရေးရ** — ဒီဖိုင် ဒါမှမဟုတ် `-api` ရဲ့ API Resource class ကို အရင်ဖတ်ရမယ်။

## Cross-repo ပြင်တဲ့အခါ

Repo ၂ ခုကို တစ်ချိန်တည်း ပြင်ရမယ်ဆိုရင် **product root (ဒီ folder) ကနေ `claude` run ပါ** — ဒါဆို repo အကုန် တစ်ခါတည်း မြင်တယ်။
Commit ကတော့ repo တစ်ခုချင်းစီ သီးသန့် (atomic မဖြစ်တာမို့ မြင်သာတဲ့ commit message ရေးပါ)။
