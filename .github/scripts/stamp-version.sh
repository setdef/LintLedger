#!/usr/bin/env bash
# Writes VERSION into lib/alibi/version.rb and into Gemfile.lock's two
# entries for the alibi gem, in the checkout it belongs to. The release
# workflow runs it on its own checkout of a tag, so the build carries the
# tag's version and no commit changes it.
#
#   stamp-version.sh VERSION

set -eu

version=${1:?usage: stamp-version.sh VERSION}
if ! [[ "$version" =~ ^0\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
  echo "stamp-version.sh: '$version' is not 0.X.Y with plain integers" >&2
  exit 2
fi

root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$root"

# -i.bak is the one in-place form that GNU sed and BSD sed share.
sed -E -i.bak "s/^( *VERSION = )\"[^\"]*\"/\\1\"$version\"/" lib/alibi/version.rb
sed -E -i.bak "s/^( +)alibi \([^)]*\)$/\\1alibi ($version)/" Gemfile.lock
rm -f lib/alibi/version.rb.bak Gemfile.lock.bak

grep -q "VERSION = \"$version\"" lib/alibi/version.rb || { echo "stamp-version.sh: lib/alibi/version.rb has no VERSION line to stamp" >&2; exit 1; }
[ "$(grep -c "^ *alibi ($version)$" Gemfile.lock)" -eq 2 ] || { echo "stamp-version.sh: Gemfile.lock does not have two alibi entries" >&2; exit 1; }
echo "stamp-version.sh: stamped $version"
