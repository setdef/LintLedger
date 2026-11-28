#!/usr/bin/env bash
# Refuses a tag that is not `v` plus three plain integers that start with
# 0 and a dot: no prerelease form, no build metadata, nothing at 1.0.0 or
# above. Prints the version, which is the tag without its `v`.
#
#   check-release-tag.sh TAG

set -eu

tag=${1:?usage: check-release-tag.sh TAG}

if ! [[ "$tag" =~ ^v0\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
  echo "check-release-tag.sh: tag '$tag' is not v0.X.Y with plain integers" >&2
  exit 1
fi
echo "${tag#v}"
