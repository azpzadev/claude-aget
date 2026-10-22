#!/usr/bin/env bash
# Product တစ်ခု (repo အများကြီးပါတဲ့) အတွက် folder + PRODUCT.md + CLAUDE.md လုပ်ပေးတယ်။
#   ./scripts/new-product.sh pos
#   ./scripts/new-product.sh pos git@github.com:org/pos-api.git git@github.com:org/pos-web.git
set -euo pipefail

W="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$W/templates/product"

product="${1:?product နာမည် လိုအပ်တယ် (ဥပမာ: pos)}"
shift || true

case "$product" in
  *[A-Z]*|*_*|*" "*) echo "✗ '$product' — lowercase နဲ့ hyphen ပဲ သုံးပါ (ဥပမာ: pos, net-panchi)"; exit 1 ;;
esac

dir="$W/projects/$product"
mkdir -p "$dir/docs"

for f in PRODUCT.md CLAUDE.md; do
  if [ -f "$dir/$f" ]; then
    echo "• $f ရှိပြီးသား — မထိဘူး"
  else
    sed "s/{{PRODUCT}}/$product/g" "$T/$f" > "$dir/$f"
    echo "✓ $f"
  fi
done

# product root ကို git repo မလုပ်ဘူး — repo တွေ nest မဖြစ်ရဘူး
[ -f "$dir/.gitignore" ] || printf '%s\n' '# repo တွေ သူ့ git သူ့ဟာ' '*/' > "$dir/.gitignore"

for url in "$@"; do
  "$W/scripts/new-project.sh" --product "$product" "$url"
done

echo
echo "ပြီးပါပြီ → $dir"
echo "နောက်တစ်ဆင့်:  $dir/PRODUCT.md ရဲ့ repo table နဲ့ boundary ကို ဖြည့်ပါ"
echo "Cross-repo အလုပ်လုပ်ချင်ရင်:  cd $dir && claude"
