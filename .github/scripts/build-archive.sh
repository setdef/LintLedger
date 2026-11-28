#!/usr/bin/env bash
# Builds Alibi with Fledge on this computer, for the platform it runs on,
# and copies the archive Fledge writes, under Fledge's own name, to
# OUTPUT_DIR: alibi-PLATFORM.tar.gz, or alibi-PLATFORM.zip on Windows.
#
#   build-archive.sh PLATFORM VERSION OUTPUT_DIR
#
# PLATFORM is the one Fledge builds for here: arm64-darwin, x86_64-linux,
# aarch64-linux, x86_64-linux-musl, aarch64-linux-musl, x64-mingw-ucrt, or
# aarch64-mingw-ucrt. VERSION is 0.X.Y. Run it from a fresh checkout of the
# tag, with the Ruby that mise.toml pins on PATH: Fledge packs the whole
# project folder, so a folder that ran the tests would carry coverage/
# into the archive. The script refuses to build when
# `git status --porcelain --ignored` prints anything, and prints it. It
# then stamps VERSION into the checkout (stamp-version.sh), which is never
# committed, and the bundle goes outside the checkout, unless BUNDLE_PATH
# says where.

set -eu

platform=${1:?usage: build-archive.sh PLATFORM VERSION OUTPUT_DIR}
version=${2:?usage: build-archive.sh PLATFORM VERSION OUTPUT_DIR}
output=${3:?usage: build-archive.sh PLATFORM VERSION OUTPUT_DIR}
case "$platform" in
  arm64-darwin | x86_64-linux | aarch64-linux | x86_64-linux-musl | aarch64-linux-musl) extension=tar.gz ;;
  x64-mingw-ucrt | aarch64-mingw-ucrt) extension=zip ;;
  *) echo "build-archive.sh: unknown platform $platform" >&2; exit 2 ;;
esac

root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$root"

found=$(git status --porcelain --ignored)
if [ -n "$found" ]; then
  echo "build-archive.sh: $root is not a fresh checkout; git status --porcelain --ignored lists:" >&2
  printf '%s\n' "$found" >&2
  exit 1
fi

"$root/.github/scripts/stamp-version.sh" "$version"

export BUNDLE_PATH=${BUNDLE_PATH:-${TMPDIR:-/tmp}/alibi-bundle}
bundle install
bundle exec rake build

# Fledge names the archive after the app and the platform it ran on, so
# the platform must be the one asked for.
archive=build/dist/alibi-$platform.$extension
if [ ! -f "$archive" ]; then
  echo "build-archive.sh: expected $archive; build/dist holds:" >&2
  ls build/dist >&2
  exit 1
fi

mkdir -p "$output"
cp "$archive" "$output/"
echo "build-archive.sh: wrote $output/alibi-$platform.$extension"
