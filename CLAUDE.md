# CLAUDE.md — workspace house style

ဒီဖိုင်က `~/workspace/projects/` အောက်ရှိ project **အကုန်လုံး** အတွက် သက်ဝင်တယ်။
Project သီးသန့်အချက်တွေကို သူ့ repo ရဲ့ `CLAUDE.md` မှာ ရေးပါ — ဒီဖိုင်မှာ မထည့်ပါနဲ့။

## Layering (Claude က cwd ကနေ အပေါ်ဆီ တက်ဖတ်ပြီး ပေါင်း load တယ်)

| လွှာ | ဖိုင် | အကြောင်းအရာ |
|---|---|---|
| Global | `~/.claude/CLAUDE.md` | ကိုယ်ရေး၊ ဘာသာစကား၊ reply style |
| Fleet | `~/workspace/CLAUDE.md` (ဒီဖိုင်) | stack default, naming, convention, တားမြစ်ချက် |
| Product | `projects/<product>/CLAUDE.md` + `PRODUCT.md` | repo map, boundary, API contract (repo အများကြီးပါရင်ပဲ) |
| Repo | `projects/.../<repo>/CLAUDE.md` | ဒီ repo ရဲ့ stack, DB, command, module |

တူတဲ့အချက်ကို ၂ နေရာ မရေးပါနဲ့။ Project ဖိုင်မှာ **ဒီ default နဲ့ ကွဲတဲ့အချက်ပဲ** ရေးပါ။

## Default stack (ကွဲရင် project CLAUDE.md မှာ ရေးပြပါ)

- **Backend** — Laravel 13 / PHP 8.3+, slim `bootstrap/app.php` style (legacy `Http/Kernel.php` မသုံး)
- **DB** — PostgreSQL
- **Test** — Pest 4 (PHPUnit underneath), `composer test`
- **Format** — Laravel Pint (`./vendor/bin/pint`), PSR-12 + Laravel preset
- **Frontend** — Vite + Tailwind 4; သီးသန့် SPA ဖြစ်ရင် Nuxt
- **Mobile** — Flutter
- **Commit** — Conventional Commits (`feat:`, `fix:`, `chore:` …), Husky + commitlint ရှိရင် သူ့ gate ကို ဖြေမယ်မလုပ်ရ

## Conventions

- ရှိပြီးသား code convention ကို အတိအကျ လိုက်ပါ။ ဖိုင်အသစ်လုပ်တိုင်း **sibling ဖိုင်ကို အရင်ဖတ်ပြီး** structure, naming, approach ကို တူအောင်လုပ်ပါ။
- Variable/method နာမည် ဖော်ပြတဲ့ပုံစံ သုံးပါ — `isRegisteredForDiscounts`, `discount()` မဟုတ်။
- Component/service အသစ်မလုပ်ခင် ရှိပြီးသား ပြန်သုံးလို့ရမရ အရင်ရှာပါ။
- Directory structure အသစ် (base folder အသစ်) ကို အတည်မပြုဘဲ မလုပ်ပါနဲ့။
- Dependency အသစ်ထည့်/ဖျက်တာ အတည်မပြုဘဲ မလုပ်ပါနဲ့။
- Verification script တွေ မရေးပါနဲ့ — feature/unit test က အတည်ပြုတဲ့အတွက် ပိုအရေးကြီးတယ်။
- Migration ရေးရင် `down()` အမြဲထည့်ပါ။ Production table ပေါ် `change()` မသုံးပါနဲ့ — column အသစ်ထည့်ပြီး backfill လုပ်ပါ။

## အမြဲတားမြစ်

- `.env` ဖိုင် မပြင်ရ၊ မဖတ်ပြရ (value တွေ မ echo ရ)။ `.env.example` ပဲ ထိရမယ်။
- `php artisan migrate:fresh` / `db:wipe` ကို production/staging connection ပေါ် ဘယ်တော့မှ မ run ရ။
- Secret, token, DSN တွေ commit မလုပ်ရ။
- `git push --force`, branch ဖျက်တာ — ခွင့်ပြုချက် မရဘဲ မလုပ်ရ။
- Dependency version pin တွေ ကိုယ်ထင်သလို မတင်ရ/မချရ။

## Workflow

1. ပြင်ခင် သက်ဆိုင်ရာဖိုင်တွေ အရင်ဖတ်ပါ — ခွင့်မတောင်းဘဲ ဖတ်လို့ရတယ်။
2. အကြီးစား feature ဖြစ်ရင် `/laravel-feature`, bug ဖြစ်ရင် `/laravel-fix` သုံးပါ။
3. ပြင်ပြီးရင် `./vendor/bin/pint --dirty` + `composer test` run ပါ။
4. Test ကျရင် ဖုံးမထားပါနဲ့ — output အတိုင်း ပြောပြပါ။

## Naming — repo နဲ့ folder

### ပုံစံ

```
<product>-<role>          ဥပမာ:  pos-api   pos-gateway   pos-web
```

- **lowercase + hyphen ပဲ**။ `_` မသုံးရ၊ CamelCase မသုံးရ၊ space ဘယ်တော့မှ မပါရ။
- Folder နာမည် = repo နာမည် = `.test` host = package name — ၄ ခု **အတိအကျတူရမယ်**။ ဒါဆို path ကို မှန်းလို့ရတယ်။
- Version/အသစ်အရွေး နာမည်မှာ မထည့်ရ — `-new`, `-v2`, `-old`, `V3` မသုံးရ (branch/tag နဲ့ ဖြေရှင်းပါ)။ ၆ လကြာရင် `-new` က နာမည်လွဲဖြစ်တယ်။
- Environment နာမည်မှာ မထည့်ရ — `-staging`, `-prod` မသုံးရ။
- Role မပါတဲ့ နာမည် မပေးရ — `temp`, `php`, `frontend`, `ai`, `package` လိုမျိုး။

### Role အမည် (ဒီစကားလုံးတွေပဲ သုံးပါ)

| Suffix | ဘာလဲ |
|---|---|
| `-api` | Backend HTTP API (business logic + DB ပိုင်ရှင်) |
| `-gateway` | Edge / middleware — auth, routing, rate limit, proxy |
| `-web` | Browser frontend (Nuxt / Blade SPA) |
| `-app` | Mobile (Flutter) |
| `-worker` | Queue / scheduled job သီးသန့် |
| `-admin` | Admin panel သီးသန့် repo ဖြစ်ရင် |
| `-schema` | DB schema / migration သီးသန့် |
| `-contracts` | OpenAPI, shared type, proto |
| `-infra` | Deploy, Docker, IaC |
| `-mcp` | MCP server |

### Repo အများကြီးပါတဲ့ product

```
projects/
├── pos/                   ← product root (git repo မဟုတ်ဘူး)
│   ├── PRODUCT.md         ★ repo map + boundary + API contract
│   ├── CLAUDE.md          ★ pos-* အကုန်အတွက် convention
│   ├── docs/
│   ├── pos-api/           (git repo)
│   ├── pos-gateway/       (git repo)
│   └── pos-web/           (git repo)
└── standalone-tool/       ← repo တစ်ခုတည်းဆိုရင် product folder မလိုဘူး
```

- Repo နဲ့ repo **nest မလုပ်ရ** — product root က git repo မဖြစ်ရဘူး (`*/` ကို gitignore ထားတယ်)။
- Product root ကနေ `claude` run ရင် repo အကုန် တစ်ခါတည်း မြင်တယ် — cross-repo အလုပ်အတွက် ဒီနည်းကို သုံးပါ။
- Repo တစ်ခုတည်းကနေ sibling ကို relative path နဲ့ ဖတ်လို့ရတယ် — `../pos-api/app/Http/Resources/`။

### Monorepo လုပ်သင့်တဲ့အခါ

အောက်က ၃ ချက် **အကုန်မှန်ရင်** repo ခွဲမထားဘဲ monorepo (`apps/api`, `apps/web`) က AI အတွက် ပိုလွယ်တယ် — commit တစ်ခုတည်းနဲ့ ပြီးတယ်၊ session တစ်ခုတည်းနဲ့ မြင်တယ်:

1. အမြဲ အတူတူ deploy တယ်
2. repo အကုန် ကိုယ်တိုင်ပိုင်တယ် (တခြားအဖွဲ့ မသုံးဘူး)
3. release cycle တူတယ်

တစ်ချက်မှားရင် repo ခွဲထားတာ မှန်တယ်။

## Docs

- Project ရဲ့ architecture/decision/runbook တွေ သူ့ `docs/` အောက်။ `~/workspace/docs/` က project ကြား ဆိုင်တဲ့ အကြောင်းအရာအတွက်။
- အကြောင်းအရာရှည်ရင် CLAUDE.md မှာ မရေးဘဲ `docs/` ထဲထည့်ပြီး ဒီကနေ link ပေးပါ။ CLAUDE.md က session တိုင်း load ဖြစ်တာမို့ တိုရမယ်။
