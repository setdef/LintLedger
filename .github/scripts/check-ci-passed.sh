#!/usr/bin/env bash
# Refuses a release unless ci.yml has a run for COMMIT, started by a push
# to trunk, that completed with the conclusion success. A run covers every
# commit pushed since the run before it started, and proves the one at its
# head, so a release is a commit that heads a passing run.
#
#   check-ci-passed.sh COMMIT
#
# Asks `gh run list` about the repository GH_REPO names, or the one the
# current folder belongs to. Needs gh, and a token that can read the
# repository's workflow runs.

set -eu

commit=${1:?usage: check-ci-passed.sh COMMIT}

# One line for each run: its status, a space, and its conclusion, which is
# empty until the run completes.
if ! runs=$(gh run list --commit "$commit" --workflow ci.yml --event push --branch trunk --limit 100 --json status,conclusion --jq '.[] | "\(.status) \(.conclusion)"'); then
  echo "check-ci-passed.sh: gh couldn't list the runs of CI for commit $commit" >&2
  exit 1
fi

if printf '%s\n' "$runs" | grep -qx 'completed success'; then
  echo "check-ci-passed.sh: CI passed for $commit"
  exit 0
fi

found=
while read -r status conclusion; do
  [ -n "$status" ] || continue
  found="$found${found:+; }status $status, conclusion ${conclusion:-none yet}"
done <<< "$runs"
echo "check-ci-passed.sh: CI has no run that completed with success for commit $commit; found: ${found:-no run of CI}" >&2
exit 1
