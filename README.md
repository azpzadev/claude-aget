# ~/workspace

AI-assisted development အတွက် workspace root။ Repo အသစ်တွေ ဒီအောက်မှာ။
(`~/www/` က Herd နဲ့ ရှိပြီးသား project တွေ — မထိဘူး)

```
~/workspace/
├── CLAUDE.md        fleet house style (projects/ အောက် အကုန်အတွက်)
├── PROJECTS.md      project index
├── .claude/
│   ├── settings.json    permission allowlist + Pint hook
│   └── commands/        /project-setup
├── templates/
│   ├── product/         repo အများကြီးပါတဲ့ product အတွက် scaffold
│   └── project/         repo တစ်ခုအတွက် scaffold
├── scripts/
│   ├── new-product.sh   product folder + PRODUCT.md
│   ├── new-project.sh   clone + scaffold
│   └── pint-hook.sh     PostToolUse formatter
├── docs/            project ကြား ဆိုင်တဲ့ doc, runbook
└── projects/        ← repo တွေ ဒီထဲ clone (git ignore)
```

## Repo တစ်ခုတည်း ထည့်တာ

```bash
~/workspace/scripts/new-project.sh git@github.com:org/repo.git
cd ~/workspace/projects/repo
claude          # ပြီးရင်  /project-setup
```

## Repo အများကြီးပါတဲ့ product ထည့်တာ

```bash
~/workspace/scripts/new-product.sh pos \
  git@github.com:org/pos-api.git \
  git@github.com:org/pos-gateway.git \
  git@github.com:org/pos-web.git

cd ~/workspace/projects/pos
# PRODUCT.md ရဲ့ repo table + boundary ဖြည့်
claude                      # ← root ကနေ run ရင် repo အကုန် မြင်တယ် (cross-repo အလုပ်)
cd pos-api && claude        # ← repo တစ်ခုတည်း အလုပ်လုပ်ရင်
```

Naming convention အတိအကျ → [CLAUDE.md](CLAUDE.md) ရဲ့ `## Naming` အပိုင်း။

## Herd

`projects/` ကို `.test` domain လိုချင်ရင် တစ်ခါပဲ:

```bash
cd ~/workspace/projects && herd park
```

## တခြားစက် (VM) ပေါ် setup

```bash
git clone git@github.com:aungzawpyae/claude-agent.git ~/workspace
mkdir -p ~/.claude && cp -r ~/workspace/claude/agents ~/workspace/claude/commands ~/workspace/claude/CLAUDE.md ~/.claude/
```

Update: `cd ~/workspace && git pull` ပြီးရင် အပေါ်က `cp` ကို ပြန် run ပါ (`laravel-*` နဲ့ agent တွေ overwrite ဖြစ်မယ်)။
`claude/` ထဲက ဖိုင်တွေက `~/.claude/` ရဲ့ copy — Mac မှာ ပြင်ရင် ဒီထဲ ပြန်ကူးပြီး commit လုပ်ပါ။
`PROJECTS.md` က template ပဲ track တယ် — စက်တစ်ခုချင်းရဲ့ project list ကို commit မလုပ်ပါနဲ့။
