#!/usr/bin/env ruby
# frozen_string_literal: true

# Checks a tag's changelog before the release publishes, and records the
# release in trunk's changelog after. The classes in release_changelog/ are
# ported from setdef/Cutter's lib/cutter/ (MIT, copyright setdef, the same as
# this project's), with the module renamed; command.rb, check.rb, and news.rb
# are this project's.
#
#   release-changelog.rb check CHANGELOG TAG TAGS_FILE [RELEASED_TAG RELEASED_CHANGELOG]
#   release-changelog.rb record CHANGELOG TRUNK_CHANGELOG TAG DATE REPOSITORY_URL [RELEASED_TAG RELEASED_CHANGELOG]
#
# See check-changelog.sh and record-release.sh, which call it.

require_relative "release_changelog/command"

exit(ReleaseChangelog::Command.new(ARGV, $stdout, $stderr).run)
