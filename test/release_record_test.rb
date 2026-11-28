# frozen_string_literal: true

require_relative("release_changelog_case")

# Checks how a release is recorded in trunk's changelog after it publishes.
class ReleaseRecordTest < ReleaseChangelogCase
  # The status, standard output, standard error, and new text of trunk's changelog, after recording the release at
  # +tag+ listed by the +tagged+ commit's changelog in the changelog +trunk+.
  def record(tagged, trunk, tag = "v0.1.0")
    arguments = ["record", "@tagged.md", "@trunk.md", tag, "2026-11-30", URL]
    after = nil
    result = run_command(arguments, { "tagged.md": tagged, "trunk.md": trunk }) do |folder|
      after = File.binread(File.join(folder, "trunk.md"))
    end
    [*result, after]
  end

  def test_recording_dates_the_release_and_moves_its_entries_under_it
    tagged = changelog("### Added\n\n- A command.\n\n### Fixed\n\n- A bug.\n")
    status, _, _, recorded = record(tagged, tagged)

    assert_equal(0, status)
    assert_equal(<<~MARKDOWN, recorded)
      # Changelog

      ## [Unreleased]

      ## [0.1.0] - 2026-11-30

      ### Added

      - A command.

      ### Fixed

      - A bug.

      [Unreleased]: #{URL}/compare/v0.1.0...HEAD
      [0.1.0]: #{URL}/releases/tag/v0.1.0
    MARKDOWN
  end

  def test_recording_leaves_entries_newer_than_the_tagged_commit_under_unreleased
    tagged = changelog("### Added\n\n- A command.\n")
    trunk = changelog("### Added\n\n- A command.\n- A flag.\n\n### Fixed\n\n- A bug.\n")
    _, _, _, recorded = record(tagged, trunk)

    assert_includes(recorded, <<~MARKDOWN)
      ## [Unreleased]

      ### Added

      - A flag.

      ### Fixed

      - A bug.

      ## [0.1.0] - 2026-11-30

      ### Added

      - A command.
    MARKDOWN
  end

  def test_recording_keeps_the_older_releases_and_their_links
    older = "## [0.1.0] - 2026-11-01\n\n### Added\n\n- A command.\n"
    foot = "\n[Unreleased]: #{URL}/compare/v0.1.0...HEAD\n[0.1.0]: #{URL}/releases/tag/v0.1.0\n"
    tagged = "#{HEAD}### Fixed\n\n- A bug.\n\n#{older}#{foot}"
    _, _, _, recorded = record(tagged, tagged, "v0.1.1")

    assert_equal(<<~MARKDOWN, recorded)
      # Changelog

      ## [Unreleased]

      ## [0.1.1] - 2026-11-30

      ### Fixed

      - A bug.

      #{older}
      [Unreleased]: #{URL}/compare/v0.1.1...HEAD
      [0.1.1]: #{URL}/releases/tag/v0.1.1
      [0.1.0]: #{URL}/releases/tag/v0.1.0
    MARKDOWN
  end

  def test_recording_a_release_that_trunk_records_already_changes_nothing
    recorded = changelog("", "## [0.1.0] - 2026-11-30\n\n### Added\n\n- A command.\n")
    status, out, _, after = record(changelog("### Added\n\n- A command.\n"), recorded)

    assert_equal(3, status)
    assert_includes(out, "already records it")
    assert_equal(recorded, after)
  end

  def test_recording_in_a_changelog_without_an_unreleased_heading_is_refused
    status, _, err, = record(changelog("### Added\n\n- A command.\n"), "# Changelog\n")

    assert_equal(1, status)
    assert_includes(err, "has no ## [Unreleased] heading")
  end

  def test_recording_keeps_the_line_endings_of_the_changelog
    tagged = changelog("### Added\n\n- A command.\n")
    _, _, _, recorded = record(tagged, tagged.gsub("\n", "\r\n"))

    assert_equal(recorded.lines.size, recorded.lines.count { |line| line.end_with?("\r\n") })
  end
end
