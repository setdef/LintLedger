#!/usr/bin/env bash
# Refuses a release unless the tag is an annotated tag that still points at
# the commit this run built, and that commit is on trunk.
#
#   check-tag-on-trunk.sh TAG COMMIT
#
# Needs gh, GH_REPO, and a token that can read the repository.

set -eu

tag=${1:?usage: check-tag-on-trunk.sh TAG COMMIT}
commit=${2:?usage: check-tag-on-trunk.sh TAG COMMIT}

kind=$(gh api "repos/$GH_REPO/git/ref/tags/$tag" --jq .object.type)
if [ "$kind" != tag ]; then
  echo "check-tag-on-trunk.sh: $tag is a lightweight tag; push an annotated tag" >&2
  exit 1
fi
object=$(gh api "repos/$GH_REPO/git/ref/tags/$tag" --jq .object.sha)
pointed=$(gh api "repos/$GH_REPO/git/tags/$object" --jq .object.sha)
if [ "$pointed" != "$commit" ]; then
  echo "check-tag-on-trunk.sh: $tag now points at $pointed, not $commit, which this run built" >&2
  exit 1
fi

status=$(gh api "repos/$GH_REPO/compare/trunk...$commit" --jq .status)
case "$status" in
  identical | behind) echo "check-tag-on-trunk.sh: $commit is on trunk" ;;
  *) echo "check-tag-on-trunk.sh: $commit is not on trunk (compare says $status)" >&2; exit 1 ;;
esac
