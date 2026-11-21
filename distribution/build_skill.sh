#!/usr/bin/env bash
# Builds the account-level "distribute" skill from the repo's master copy.
# Output: distribution/distribute-skill.zip (upload in Claude: Settings > Skills).
# Run this again any time you change the engine or a brand file.
set -euo pipefail
cd "$(dirname "$0")/.."

out_dir="$(mktemp -d)"
skill_dir="$out_dir/distribute"
mkdir -p "$skill_dir/brands"

# Same engine, but brand files are read from the skill's own folder instead of the repo.
sed -e 's#distribution/brands/#brands/#g' \
    -e '/^# Distribution engine$/a\
\
Brand files are in the `brands/` folder inside this skill. They are copies; the master versions live in the june-mg repo.' \
  .claude/skills/distribute/SKILL.md > "$skill_dir/SKILL.md"
cp distribution/brands/*.json "$skill_dir/brands/"

rm -f distribution/distribute-skill.zip
(cd "$out_dir" && zip -qr - distribute) > distribution/distribute-skill.zip
rm -rf "$out_dir"
echo "Built distribution/distribute-skill.zip"
