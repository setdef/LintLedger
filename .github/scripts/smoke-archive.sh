#!/usr/bin/env bash
# Unpacks a release archive and runs `alibi` from it with an empty folder
# as PATH, so that any Ruby installed on this computer is out of reach.
# Fails when `alibi --version` doesn't print VERSION, or when any run
# exits with another status than expected, or runs longer than 60 seconds.
#
#   smoke-archive.sh ARCHIVE VERSION
#
# Needs no Ruby and no mise: bash, tar (or PowerShell, for a .zip), and a
# kill that ends a process.

set -eu

archive=${1:?usage: smoke-archive.sh ARCHIVE VERSION}
version=${2:?usage: smoke-archive.sh ARCHIVE VERSION}
case "$archive" in /* | [A-Za-z]:*) ;; *) archive=$PWD/$archive ;; esac
[ -f "$archive" ] || { echo "smoke-archive.sh: no file $archive" >&2; exit 1; }

work=$(mktemp -d "${TMPDIR:-/tmp}/alibi-smoke.XXXXXX")
trap 'rm -rf "$work"' EXIT
mkdir "$work/unpacked" "$work/empty" "$work/project"

case "$archive" in
  *.tar.gz) tar -xzf "$archive" -C "$work/unpacked" ;;
  *.zip)
    powershell.exe -NoProfile -NonInteractive -Command \
      "Expand-Archive -LiteralPath '$(cygpath -w "$archive")' -DestinationPath '$(cygpath -w "$work/unpacked")'" ;;
  *) echo "smoke-archive.sh: $archive is neither .tar.gz nor .zip" >&2; exit 2 ;;
esac

folders=$(find "$work/unpacked" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')
if [ "$folders" -ne 1 ]; then
  echo "smoke-archive.sh: $archive does not unpack to one top folder" >&2
  exit 1
fi

program=
for candidate in "$work"/unpacked/*/alibi "$work"/unpacked/*/alibi.exe; do
  [ -f "$candidate" ] && program=$candidate
done
[ -n "$program" ] || { echo "smoke-archive.sh: no alibi program in $archive" >&2; exit 1; }

# Runs the program in the project folder with an empty PATH, ends it after
# 60 seconds, and prints what it printed. Sets $status to its exit status.
run() {
  local limit=60 pid watcher
  status=0
  (cd "$work/project" && exec env PATH="$work/empty" "$program" "$@") > "$work/output.txt" 2>&1 &
  pid=$!
  (sleep "$limit"; echo "smoke-archive.sh: alibi $* ran longer than $limit seconds" >&2; kill -9 "$pid" 2>/dev/null) &
  watcher=$!
  wait "$pid" || status=$?
  kill "$watcher" 2>/dev/null || true
  wait "$watcher" 2>/dev/null || true
  cat "$work/output.txt"
}

expect() {
  local wanted=$1
  shift
  run "$@"
  if [ "$status" -ne "$wanted" ]; then
    echo "smoke-archive.sh: alibi $* exited with $status, expected $wanted" >&2
    exit 1
  fi
}

printed=$(expect 0 --version)
case "$printed" in
  "$version" | "alibi $version") echo "alibi --version: $printed" ;;
  *) echo "smoke-archive.sh: alibi --version printed '$printed', expected '$version'" >&2; exit 1 ;;
esac
