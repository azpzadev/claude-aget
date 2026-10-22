#!/usr/bin/env bash
# Repo အသစ် clone လုပ်ပြီး Claude scaffold တပ်ပေးတယ်။
#   ./scripts/new-project.sh git@github.com:org/repo.git [folder-name]
# clone မလုပ်ဘဲ ရှိပြီးသား folder ကို scaffold တပ်ချင်ရင်:
#   ./scripts/new-project.sh --existing projects/repo
set -euo pipefail

W="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$W/templates/project"

if [ "${1:-}" = "--existing" ]; then
  dest="$(cd "${2:?folder လိုအပ်တယ်}" && pwd)"
  name="$(basename "$dest")"
else
  url="${1:?git URL လိုအပ်တယ်}"
  name="${2:-$(basename "$url" .git)}"
  dest="$W/projects/$name"
  [ -e "$dest" ] && { echo "✗ $dest ရှိပြီးသား"; exit 1; }
  git clone "$url" "$dest"
fi

cd "$dest"

# CLAUDE.md — ရှိပြီးသားဆိုရင် မထိဘူး
if [ -f CLAUDE.md ]; then
  echo "• CLAUDE.md ရှိပြီးသား — မထိဘူး"
else
  sed "s/{{PROJECT}}/$name/" "$T/CLAUDE.md" > CLAUDE.md
  echo "✓ CLAUDE.md scaffold တပ်ပြီး"
fi

# AGENTS.md — CLAUDE.md ကို symlink (Codex/Cursor တွေအတွက်)
if [ -f AGENTS.md ] && [ ! -L AGENTS.md ]; then
  echo "⚠ AGENTS.md က ဖိုင်အစစ် — CLAUDE.md နဲ့ ထပ်နေတယ်။ ကိုယ်တိုင် merge လုပ်ပါ"
elif [ ! -e AGENTS.md ]; then
  ln -s CLAUDE.md AGENTS.md
  echo "✓ AGENTS.md → CLAUDE.md symlink"
fi

mkdir -p .claude/commands docs/decisions docs/runbooks
[ -f .claude/settings.json ] || cp "$T/.claude/settings.json" .claude/settings.json
[ -f docs/architecture.md ] || printf '# Architecture — %s\n\n<!-- TODO -->\n' "$name" > docs/architecture.md

# .gitignore မှာ Claude local ဖိုင် ထည့်
if [ -f .gitignore ] && ! grep -q 'settings.local.json' .gitignore; then
  printf '\n' >> .gitignore
  cat "$T/gitignore-additions.txt" >> .gitignore
  echo "✓ .gitignore update"
fi

# PROJECTS.md index မှာ တစ်လိုင်းထည့်
if ! grep -q "| $name |" "$W/PROJECTS.md" 2>/dev/null; then
  printf '| %s | | active | https://%s.test | |\n' "$name" "$name" >> "$W/PROJECTS.md"
  echo "✓ PROJECTS.md မှာ ထည့်ပြီး"
fi

echo
echo "ပြီးပါပြီ → $dest"
echo "နောက်တစ်ဆင့်:  cd $dest && claude   ပြီးရင် /init သုံးပြီး CLAUDE.md ကို ဖြည့်ပါ"
