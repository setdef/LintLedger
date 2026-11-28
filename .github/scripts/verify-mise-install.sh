#!/usr/bin/env bash
# Installs Alibi the way README.md says, through mise's github backend, with
# the recipe's `version = "latest"` replaced by VERSION, and runs
# `alibi --version` with no Ruby reachable. Fails when the install
# fails, when a Ruby is on the PATH the program runs with, when
# `alibi --version` doesn't print VERSION, or when any command runs longer
# than 120 seconds.
#
#   verify-mise-install.sh VERSION RECIPE
#
# RECIPE is the number of the toml block under README.md's Install heading
# that fits this computer: 1 for macOS, Linux with glibc, and Windows, and 2
# for Linux with musl. Only the blocks under that heading count, and the
# script fails unless it has exactly two, so that a toml block elsewhere in
# README.md can't shift the numbering. Needs mise on PATH, and bash and awk.
# Run it in a folder of its own: it writes mise.toml there.

set -eu

version=${1:?usage: verify-mise-install.sh VERSION RECIPE}
recipe=${2:?usage: verify-mise-install.sh VERSION RECIPE}
root=$(cd "$(dirname "$0")/../.." && pwd)

# Prints the number of fenced toml blocks under the Install heading, or, given
# a block's number, the lines of that block.
install_blocks() {
  awk -v wanted="${1:-}" '
    /^## / { in_install = ($0 == "## Install") }
    in_install && /^```toml$/ { count++; in_block = 1; next }
    /^```$/ { in_block = 0 }
    in_install && in_block && count == wanted
    END { if (wanted == "") print count + 0 }
  ' "$root/README.md"
}
blocks=$(install_blocks)
[ "$blocks" = 2 ] || { echo "verify-mise-install.sh: README.md's Install section has $blocks toml blocks, not the 2 this script numbers" >&2; exit 1; }
readme_recipe=$(install_blocks "$recipe")
[ -n "$readme_recipe" ] || { echo "verify-mise-install.sh: README.md's Install section has no toml block number $recipe" >&2; exit 1; }
echo "verify-mise-install.sh: the recipe README.md gives:"
echo "$readme_recipe"

# The recipe says `latest`. By default (minimum_release_age, 24 hours) mise
# won't pick a release published less than 24 hours ago for `latest`, but it
# doesn't hold back an exact version. This script runs right after a release
# is published and checks that release, so it writes VERSION in place of
# `latest`.
echo "$readme_recipe" | awk -v version="$version" '
  $0 == "version = \"latest\"" { print "version = \"" version "\""; replaced++; next }
  { print }
  END { exit replaced != 1 }
' > mise.toml || { echo "verify-mise-install.sh: README.md's recipe $recipe doesn't have exactly one line: version = \"latest\"" >&2; exit 1; }
echo "verify-mise-install.sh: the mise.toml this script runs mise on:"
cat mise.toml

# Ends the command after 120 seconds. The watcher's output goes nowhere, so
# that its sleep holds no pipe.
limited() {
  local pid watcher status=0
  rm -f timed-out
  "$@" &
  pid=$!
  (sleep 120; : > timed-out; kill -9 "$pid") > /dev/null 2>&1 &
  watcher=$!
  wait "$pid" || status=$?
  kill "$watcher" > /dev/null 2>&1 || true
  if [ -e timed-out ]; then
    echo "verify-mise-install.sh: $* ran longer than 120 seconds" >&2
    return 124
  fi
  return "$status"
}

mise=$(command -v mise)
export MISE_TRUSTED_CONFIG_PATHS=$PWD
limited "$mise" install

# The program runs with the folder of mise alone on PATH, plus the folder
# mise adds for the tool.
safe_path=$(dirname "$mise")
if PATH="$safe_path" command -v ruby > /dev/null 2>&1; then
  echo "verify-mise-install.sh: a ruby is on $safe_path, so the run would prove nothing" >&2
  exit 1
fi
printed=$(limited env PATH="$safe_path" "$mise" exec -- alibi --version)
case "$printed" in
  "$version" | "alibi $version") echo "mise exec -- alibi --version: $printed" ;;
  *) echo "verify-mise-install.sh: alibi --version printed '$printed', expected '$version'" >&2; exit 1 ;;
esac
if limited env PATH="$safe_path" "$mise" exec -- ruby -v > /dev/null 2>&1; then
  echo "verify-mise-install.sh: mise put a ruby on PATH" >&2
  exit 1
fi
