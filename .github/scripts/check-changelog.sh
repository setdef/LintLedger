#!/usr/bin/env bash
# Refuses a release unless the changelog at the tagged commit lists something
# under Unreleased that the release before it didn't, the tag is newer than
# every other v0.X.Y tag, and the tag's version is the one the entries call
# for: 0.(X+1).0 when an entry is marked **Breaking:** or is under Removed,
# otherwise 0.X.(Y+1), and 0.1.0 for the first release. Run it in the checkout
# of the tagged commit.
#
#   check-changelog.sh TAG
#
# Needs gh, GH_REPO, a token that can read the repository, and ruby.

set -eu

tag=${1:?usage: check-changelog.sh TAG}
here=$(cd "$(dirname "$0")" && pwd)

folder=$(mktemp -d)
trap 'rm -rf "$folder"' EXIT
"$here/changelog-inputs.sh" "$tag" "$folder"

released=()
if [ -e "$folder/released-tag" ]; then
  released=("$(cat "$folder/released-tag")" "$folder/released-changelog")
fi
ruby "$here/release-changelog.rb" check CHANGELOG.md "$tag" "$folder/tags" ${released[@]+"${released[@]}"}
