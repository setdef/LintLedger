#!/usr/bin/env bash
# Prints the release notes: what CHANGELOG.md lists under Unreleased, in the
# checkout it belongs to, which is the tagged commit's.
#
#   release-notes.sh

set -eu

root=$(cd "$(dirname "$0")/../.." && pwd)
notes=$(awk '/^## \[Unreleased\]/ { in_section = 1; next } /^## / || /^\[[^]]*\]: / { in_section = 0 } in_section' "$root/CHANGELOG.md")
if [ -z "$(printf '%s' "$notes" | tr -d '[:space:]')" ]; then
  echo "Nothing is listed under Unreleased in CHANGELOG.md."
else
  printf '%s\n' "$notes"
fi
