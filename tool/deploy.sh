#!/usr/bin/env bash
# Baut beide Varianten und pusht sie auf gh-pages:
#   /quokkadoku/        Luisa-Build (mit Alex-Bannern und Easter Eggs)
#   /quokkadoku/alle/   allgemeiner Build
set -e
cd "$(dirname "$0")/.."
export PATH="/c/dev/flutter/bin:$PATH" MSYS_NO_PATHCONV=1
flutter build web --release --base-href "/quokkadoku/alle/"
rm -rf build/pages && mkdir -p build/pages/alle && cp -r build/web/. build/pages/alle/
flutter build web --release --base-href "/quokkadoku/" --dart-define=LUISA=true
cp -r build/web/. build/pages/
cd build/pages
git init -q -b gh-pages && git add -A && git -c core.autocrlf=false commit -qm deploy
git push -f -q https://github.com/Kapilz82/quokkadoku.git gh-pages 2>&1 | grep -v '^warning' || true
cd ../.. && rm -rf build/pages
echo "deployed"
