#!/usr/bin/env bash
# Refuses a release unless every other job of this workflow run succeeded on
# its latest attempt. A skipped job counts as failed.
#
#   check-run-jobs.sh OWN_JOB_ID
#
# OWN_JOB_ID is the id of the job that runs this script (`job.check_run_id`),
# which is still in progress and so is left out. A job that needs that job
# isn't listed yet. Needs gh, GH_REPO, GITHUB_RUN_ID, and a token that can
# read the repository's workflow runs.

set -eu

own=${1:?usage: check-run-jobs.sh OWN_JOB_ID}
case "$own" in
  *[!0-9]* | "") echo "check-run-jobs.sh: '$own' is not a job id" >&2; exit 2 ;;
esac

if ! unfinished=$(gh api --paginate "repos/$GH_REPO/actions/runs/$GITHUB_RUN_ID/jobs?filter=latest&per_page=100" \
  --jq ".jobs[] | select(.id != $own) | select(.conclusion != \"success\") | \"\\(.name): \\(.status), \\(.conclusion)\""); then
  echo "check-run-jobs.sh: gh couldn't list the jobs of run $GITHUB_RUN_ID; run the release job again" >&2
  exit 1
fi

if [ -n "$unfinished" ]; then
  echo "check-run-jobs.sh: these jobs of this run did not succeed, so nothing is released:" >&2
  printf '%s\n' "$unfinished" >&2
  exit 1
fi
echo "check-run-jobs.sh: every other job of run $GITHUB_RUN_ID succeeded"
