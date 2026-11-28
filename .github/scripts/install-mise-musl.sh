#!/usr/bin/env bash
# Installs mise 2026.10.11 from mise's own release for Linux with musl, into
# FOLDER, after checking the download against a SHA-256 written here. Alpine's
# package of mise is older than the version that mise.toml and CI pin, so the
# install proof in an Alpine image uses this instead.
#
#   install-mise-musl.sh FOLDER
#
# Keep version and the checksums in step with the `version:` that CI gives
# jdx/mise-action. The checksums are GitHub's record of each asset of
# https://github.com/jdx/mise/releases/tag/v2026.10.11, which a download of
# each asset reproduced. Needs bash, wget, tar, and sha256sum, which Alpine's
# busybox has. Each wget ends after 120 seconds.

set -eu

folder=${1:?usage: install-mise-musl.sh FOLDER}
version=2026.10.11

case "$(uname -m)" in
  x86_64)
    arch=x64
    sha256=b2d015b101c1b5e3a0a45f706d0a3a16cab57a6070d7bd43140614aeb7c3fed4 ;;
  aarch64)
    arch=arm64
    sha256=169b397cb8894e2f79098726f410951111d6d0d2a7d57232871d0d23dd7f6f31 ;;
  *)
    echo "install-mise-musl.sh: no checksum for $(uname -m)" >&2
    exit 1 ;;
esac

asset=mise-v$version-linux-$arch-musl.tar.gz
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

echo "install-mise-musl.sh: downloading $asset from github.com/jdx/mise" >&2
wget -q -T 120 -O "$work/$asset" "https://github.com/jdx/mise/releases/download/v$version/$asset"
echo "$sha256  $work/$asset" | sha256sum -c - >&2
tar -xzf "$work/$asset" -C "$work" mise/bin/mise
install -m 755 "$work/mise/bin/mise" "$folder/mise"
"$folder/mise" --version >&2
