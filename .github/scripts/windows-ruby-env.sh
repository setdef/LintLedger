#!/bin/sh
# Gives a Windows job, after jdx/mise-action has installed mise.toml's
# Ruby and MSYS2 and exported their environment, the rest of what
# ruby/setup-ruby and `ridk enable` would give it:
#
# - TMPDIR, HOME, and MSYS2_PATH_TYPE, as setup-ruby exports them.
#   Without TMPDIR, Ruby's Dir.tmpdir is TMP, a short 8.3 path such as
#   C:\Users\RUNNER~1\..., which some gems' builds can't use.
# - MSYS2's usr/bin, behind its compiler's folder, and LANG from MSYS2's
#   locale, as `ridk enable` sets them; mise.toml and
#   .config/mise/windows.env set the rest. MSYS2's locale doesn't start
#   under another MSYS2's bash (it exits 127 with no message), so LANG is
#   then C.

set -eu

: "${MSYS2_PATH:?mise.toml sets no MSYS2_PATH}"
msys2=$(cygpath -u "$MSYS2_PATH")
locale=$("$msys2/usr/bin/locale" -uU || true)
case "$locale" in *UTF-8*) ;; *) locale=C ;; esac
mingw=$(cygpath -w "$msys2/${MSYSTEM_PREFIX:?.config/mise/windows.env sets no MSYSTEM_PREFIX}/bin")

{
  echo "TMPDIR=$RUNNER_TEMP"
  echo "HOME=$USERPROFILE"
  echo "MSYS2_PATH_TYPE=inherit"
  echo "LANG=$locale"
} >> "$GITHUB_ENV"

# GITHUB_PATH puts each later line ahead of the earlier ones.
{
  cygpath -w "$msys2/usr/bin"
  echo "$mingw"
} >> "$GITHUB_PATH"
