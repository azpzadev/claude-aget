#!/usr/bin/env bash
# Repo အသစ် clone လုပ်ပြီး Claude scaffold တပ်ပေးတယ်။
#   ./scripts/new-project.sh git@github.com:org/repo.git [folder-name]
# Product အောက်ထဲ clone ချင်ရင်:
#   ./scripts/new-project.sh --product pos git@github.com:org/pos-api.git
# clone မလုပ်ဘဲ ရှိပြီးသား folder ကို scaffold တပ်ချင်ရင်:
#   ./scripts/new-project.sh --existing projects/repo
set -euo pipefail
product=""

W="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$W/templates/project"

parent="$W/projects"
if [ "${1:-}" = "--product" ]; then
  product="${2:?product နာမည် လိုအပ်တယ်}"
  parent="$W/projects/$product"
  [ -d "$parent" ] || { echo "✗ product '$product' မရှိဘူး — အရင် scripts/new-product.sh $product run ပါ"; exit 1; }
  shift 2
fi

if [ "${1:-}" = "--existing" ]; then
  dest="$(cd "${2:?folder လိုအပ်တယ်}" && pwd)"
  name="$(basename "$dest")"
  # product folder အောက်မှာဆိုရင် parent နာမည်ကို product အဖြစ် သတ်မှတ်
  gp="$(basename "$(dirname "$dest")")"
  [ "$gp" != "projects" ] && [ -f "$(dirname "$dest")/PRODUCT.md" ] && product="$gp"
else
  url="${1:?git URL လိုအပ်တယ်}"
  name="${2:-$(basename "$url" .git)}"
  case "$name" in
    *[A-Z]*|*_*|*" "*) echo "⚠ '$name' — lowercase + hyphen က convention ပါ (ဥပမာ: ${name}-api)"; ;;
  esac
  dest="$parent/$name"
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
  prod_label="${product:-—}"
  printf '| %s | %s | | active | https://%s.test | |\n' "$prod_label" "$name" "$name" >> "$W/PROJECTS.md"
  echo "✓ PROJECTS.md မှာ ထည့်ပြီး"
fi

echo
echo "ပြီးပါပြီ → $dest"
echo "နောက်တစ်ဆင့်:  cd $dest && claude   ပြီးရင် /init သုံးပြီး CLAUDE.md ကို ဖြည့်ပါ"
