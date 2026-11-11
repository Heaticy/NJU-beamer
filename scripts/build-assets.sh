#!/usr/bin/env bash
# Regenerate shared-assets/ from assets-src/nju-assets.tex. The themes only
# read the committed PDFs, so this script is needed only after editing the
# artwork. Requires XeLaTeX with njuvisual (TeX Live) and pdfseparate.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$root/.beamer-cache/assets"
mkdir -p "$work"

xelatex -interaction=nonstopmode -halt-on-error -output-directory="$work" \
  "$root/assets-src/nju-assets.tex" >/dev/null

# Page order of assets-src/nju-assets.tex.
targets=(
  backgrounds/nju-master.pdf
  logos/nju-emblem.pdf
  logos/nju-emblem-white.pdf
  logos/nju-lockup.pdf
  logos/nju-lockup-white.pdf
  logos/nju-skyline.pdf
  logos/nju-skyline-white.pdf
  logos/nju-motto.pdf
  logos/nju-motto-white.pdf
  backgrounds/nju-ribbons.pdf
)
pages="$(pdfinfo "$work/nju-assets.pdf" | awk '/^Pages:/ {print $2}')"
[[ "$pages" == "${#targets[@]}" ]] || {
  echo "Expected ${#targets[@]} pages in nju-assets.pdf, got $pages" >&2
  exit 1
}
for i in "${!targets[@]}"; do
  pdfseparate -f $((i + 1)) -l $((i + 1)) "$work/nju-assets.pdf" \
    "$root/shared-assets/${targets[$i]}"
  echo "  -> shared-assets/${targets[$i]}"
done
