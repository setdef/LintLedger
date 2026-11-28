#!/usr/bin/env bash
# Records a published release in trunk's changelog: gives the release a dated
# heading, moves under it the entries that the tagged commit's CHANGELOG.md
# listed under Unreleased, leaves any newer entry there, updates the link
# definitions at the foot, and pushes that to trunk as one commit. When a push
# loses a race with another push, it fetches trunk and writes the commit
# again, up to 3 tries in all. It does nothing when trunk's changelog has the
# release's heading already, so running it again after a failure is safe. Run
# it in the checkout of the tagged commit, which must have the tag.
#
#   record-release.sh TAG [REMOTE]
#
# REMOTE is the repository to push to, the URL of origin by default. Needs
# gh, git, ruby, GH_REPO, and a token that can write the repository's
# contents, which gh takes from GH_TOKEN. The token goes to git in a file
# that only this user can read, never in a command line or the environment,
# and the file is deleted when the script ends. A push made with the run's
# token starts no workflow, so trunk's CI doesn't run for the record commit.

set -eu

tag=${1:?usage: record-release.sh TAG [REMOTE]}
remote=${2:-$(git remote get-url origin)}
here=$(cd "$(dirname "$0")" && pwd)
repository_url=${GITHUB_SERVER_URL:-https://github.com}/${GH_REPO:?record-release.sh: GH_REPO is not set}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir "$work/inputs"

git show "$tag^{commit}:CHANGELOG.md" > "$work/tagged.md"
"$here/changelog-inputs.sh" "$tag" "$work/inputs"
released=()
if [ -e "$work/inputs/released-tag" ]; then
  released=("$(cat "$work/inputs/released-tag")" "$work/inputs/released-changelog")
fi

# GitHub takes a run's token as the password of any user name. Git's own
# store helper reads it from a file.
credentials=()
token=$(gh auth token 2> /dev/null || true)
if [ -n "$token" ]; then
  server=${GITHUB_SERVER_URL:-https://github.com}
  (umask 077 && printf '%s://x-access-token:%s@%s\n' "${server%%://*}" "$token" "${server#*://}" > "$work/credentials")
  credentials=(-c credential.helper= -c "credential.helper=store --file=$work/credentials")
fi

clone=$work/trunk
git init -q "$clone"
git -C "$clone" remote add origin "$remote"
# Runs git in the clone, with the credentials when there are any.
clone_git() {
  git -C "$clone" ${credentials[@]+"${credentials[@]}"} "$@"
}

# The account GitHub shows as the actor of what the run's token does.
export GIT_AUTHOR_NAME="github-actions[bot]" GIT_COMMITTER_NAME="github-actions[bot]"
export GIT_AUTHOR_EMAIL="41898282+github-actions[bot]@users.noreply.github.com"
export GIT_COMMITTER_EMAIL="41898282+github-actions[bot]@users.noreply.github.com"

lost=$'\\[rejected\\] \\((non-fast-forward|fetch first)\\)'
for try in 1 2 3; do
  # Each try starts from trunk as it stands then, so a try after a lost race
  # writes the changelog again on the new tip.
  clone_git fetch -q --depth 1 origin trunk
  clone_git checkout -q --force --detach FETCH_HEAD
  status=0
  ruby "$here/release-changelog.rb" record "$work/tagged.md" "$clone/CHANGELOG.md" "$tag" "$(date -u +%F)" "$repository_url" ${released[@]+"${released[@]}"} || status=$?
  case $status in
    0) ;;
    3) exit 0 ;;
    *) exit 1 ;;
  esac
  clone_git add CHANGELOG.md
  clone_git commit -q -m "chore: record $tag in the changelog"
  if output=$(clone_git push --porcelain origin HEAD:trunk 2>&1); then
    echo "record-release.sh: recorded $tag on trunk" >&2
    exit 0
  fi
  if printf '%s\n' "$output" | grep -qE "$lost"; then
    echo "record-release.sh: push $try lost a race with another push to trunk" >&2
    continue
  fi
  printf '%s\n' "$output" >&2
  echo "record-release.sh: the push of the record commit failed" >&2
  exit 1
done
echo "record-release.sh: trunk moved under every try to record $tag; run the release job again to record it" >&2
exit 1
