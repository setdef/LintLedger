#!/bin/sh
# Builds the archive for a musl platform inside Alpine's Ruby image, which the
# workflow runs with `docker run`, the checkout mounted and made the working
# folder: GitHub's JavaScript actions can't run in an Alpine job container on
# an ARM runner.
#
#   build-archive-alpine.sh PLATFORM VERSION OUTPUT_DIR
#
# Installs what the build needs that the image lacks: git, for Fledge's gem
# and for the checkout check, bash, a C toolchain for the gems with
# extensions, and the tools Fledge's license audit reads with.

set -eu

apk add --no-cache bash git binutils tar build-base pkgconf
git config --global --add safe.directory "$PWD"
exec bash .github/scripts/build-archive.sh "$@"
