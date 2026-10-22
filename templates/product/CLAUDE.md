# CLAUDE.md — {{PRODUCT}} (product level)

ဒီဖိုင်က `{{PRODUCT}}-*` repo **အကုန်လုံး** အတွက် သက်ဝင်တယ် (Claude က parent dir ဆီ တက်ဖတ်တယ်)။
Repo တစ်ခုတည်း ဆိုင်တာက သူ့ repo ရဲ့ `CLAUDE.md` ထဲ။

## အရင်ဆုံး ဒါဖတ်

**[`PRODUCT.md`](PRODUCT.md)** — repo map, request လမ်းကြောင်း, boundary, API contract။
ဘယ် repo ကို ပြင်ရမလဲ မသေချာရင် အဲ့ဒီဖိုင်က အဖြေပေးတယ်။

## စည်းကမ်း

- Repo ရဲ့ **boundary ကို မကျော်ရ** — `PRODUCT.md` ရဲ့ ပိုင်ရှင် table ကို လိုက်နာပါ။
- Sibling repo ထဲက code ကို ဖတ်တာ ရတယ် (relative path: `../{{PRODUCT}}-api`)။ သို့သော် **ဖတ်ရမယ့်အချိန်မှ ဖတ်ပါ** — code ကို ကော်ပီ မယူပါနဲ့၊ contract ကိုပဲ လိုက်ပါ။
- Repo ၂ ခု ပြောင်းရမယ့် အလုပ်ဆိုရင် **အရင်ပြောပြပါ** — ဘယ်ဖိုင်တွေ ဘယ် repo မှာ ပြောင်းမလဲ list ပြပြီးမှ စပါ။
- Shared type / DTO တွေကို repo ၂ ခုမှာ ထပ်မရေးပါနဲ့ — `PRODUCT.md` ရဲ့ contract ဖိုင်က အမှန်တရား။
- Terminology တူတူသုံးပါ (ဥပမာ "shop" ကို `-api` မှာ `shop`, `-web` မှာ `store` လို့ မခေါ်ပါနဲ့)။

## Environment

<!-- local မှာ ဘယ် port, ဘယ် DB, ဘယ် queue သုံးလဲ -->
