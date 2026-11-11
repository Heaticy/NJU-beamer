#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

version="$(tr -d '[:space:]' < VERSION)"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "Invalid VERSION: $version" >&2
  exit 1
}
grep -Fq "## v$version " CHANGELOG.md || {
  echo "CHANGELOG.md has no entry for v$version" >&2
  exit 1
}

while IFS= read -r theme; do
  grep -Fq "v$version" "$theme" || {
    echo "Version mismatch in $theme: expected v$version" >&2
    exit 1
  }
done < <(find themes -maxdepth 1 -type f -name '*.sty' | sort)

bash -n scripts/audit-pdf.sh scripts/check-release.sh scripts/build-assets.sh

if find . -type f -not -path './.git/*' -not -path './build/*' -not -path './.beamer-cache/*' \
    \( -name '*.aux' -o -name '*.fdb_latexmk' -o -name '*.fls' -o -name '*.log' \
       -o -name '*.nav' -o -name '*.out' -o -name '*.snm' -o -name '*.toc' \
       -o -name '*.vrb' -o -name '*.xdv' \) | grep -q .; then
  echo 'Generated LaTeX files found outside build/ or .beamer-cache/.' >&2
  exit 1
fi

printf 'Release metadata v%s passed.\n' "$version"
