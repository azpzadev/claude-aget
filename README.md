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
├── templates/project/   repo အသစ်အတွက် scaffold
├── scripts/
│   ├── new-project.sh   clone + scaffold
│   └── pint-hook.sh     PostToolUse formatter
├── docs/            project ကြား ဆိုင်တဲ့ doc, runbook
└── projects/        ← repo တွေ ဒီထဲ clone (git ignore)
```

## Repo အသစ် ထည့်တာ

```bash
~/workspace/scripts/new-project.sh git@github.com:org/repo.git
cd ~/workspace/projects/repo
claude          # ပြီးရင်  /project-setup
```

## Herd

`projects/` ကို `.test` domain လိုချင်ရင် တစ်ခါပဲ:

```bash
cd ~/workspace/projects && herd park
```
