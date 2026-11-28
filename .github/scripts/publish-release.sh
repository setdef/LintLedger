#!/usr/bin/env bash
# Publishes a GitHub release of an existing tag through a draft: deletes a
# draft an earlier run left, creates the draft with the archives, uploads
# SHA256SUMS last, and publishes. It names no target commit, since GitHub
# refuses a target when trunk's tip has changed workflow files.
#
#   publish-release.sh TAG TITLE FILES_FOLDER NOTES_FILE
#
# FILES_FOLDER holds the files to publish and SHA256SUMS, which is uploaded
# last. Needs gh, GH_REPO, and a token that can write the repository's
# contents. Each gh command is ended after 5 minutes.

set -eu

tag=${1:?usage: publish-release.sh TAG TITLE FILES_FOLDER NOTES_FILE}
title=${2:?usage: publish-release.sh TAG TITLE FILES_FOLDER NOTES_FILE}
folder=${3:?usage: publish-release.sh TAG TITLE FILES_FOLDER NOTES_FILE}
notes=${4:?usage: publish-release.sh TAG TITLE FILES_FOLDER NOTES_FILE}

[ -f "$folder/SHA256SUMS" ] || { echo "publish-release.sh: $folder has no SHA256SUMS" >&2; exit 1; }

# Ends a gh command that outlasts 300 seconds.
limited() {
  timeout 300 gh "$@"
}

state=$(limited release view "$tag" --json isDraft --jq .isDraft 2> /dev/null || echo none)
case "$state" in
  false) echo "publish-release.sh: GitHub has a published release $tag already" >&2; exit 1 ;;
  true)
    echo "publish-release.sh: deleting the draft of $tag that an earlier run left" >&2
    limited release delete "$tag" --yes ;;
esac

files=()
for file in "$folder"/*; do
  [ "$(basename "$file")" = SHA256SUMS ] || files+=("$file")
done

fail() {
  echo "publish-release.sh: $1; the release $tag was not published, and its draft is deleted; run the release job again" >&2
  limited release delete "$tag" --yes || true
  exit 1
}

limited release create "$tag" "${files[@]}" --draft --verify-tag --title "$title" --notes-file "$notes" || fail "creating the draft failed"
limited release upload "$tag" "$folder/SHA256SUMS" || fail "uploading SHA256SUMS failed"
limited release edit "$tag" --draft=false || {
  echo "publish-release.sh: publishing $tag failed; the release may be published; run the release job again" >&2
  exit 1
}
echo "publish-release.sh: published $tag"
