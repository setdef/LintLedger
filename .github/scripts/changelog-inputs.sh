#!/usr/bin/env bash
# Writes into FOLDER what release-changelog.rb needs to know about the
# releases before TAG: `tags`, the other v0.X.Y tags of the repository, one
# to a line, and, when one of them has a published release, `released-tag`
# for the newest such tag and `released-changelog` for CHANGELOG.md as that
# tag has it.
#
#   changelog-inputs.sh TAG FOLDER
#
# Needs gh, GH_REPO, and a token that can read the repository. Each gh
# command is ended after 5 minutes.

set -eu

tag=${1:?usage: changelog-inputs.sh TAG FOLDER}
folder=${2:?usage: changelog-inputs.sh TAG FOLDER}

# Ends a gh command that outlasts 300 seconds.
limited() {
  timeout 300 gh "$@"
}

refs=$(limited api --paginate "repos/$GH_REPO/git/matching-refs/tags/v" --jq '.[].ref | ltrimstr("refs/tags/")')
# grep exits 1 when no tag is left, which is no failure.
printf '%s\n' "$refs" | { grep -E '^v0\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' || true; } | { grep -vxF "$tag" || true; } | sort -V -r > "$folder/tags"

while read -r other; do
  # A draft has no release by this name, as far as the tags endpoint tells.
  if [ "$(limited api "repos/$GH_REPO/releases/tags/$other" --jq '.draft' 2> /dev/null || echo none)" = false ]; then
    echo "changelog-inputs.sh: $other is the newest tag with a published release" >&2
    echo "$other" > "$folder/released-tag"
    limited api "repos/$GH_REPO/contents/CHANGELOG.md?ref=$other" -H "Accept: application/vnd.github.raw" > "$folder/released-changelog"
    break
  fi
done < "$folder/tags"
