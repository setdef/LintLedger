# frozen_string_literal: true

require_relative("release_changelog_case")

# Checks what stops a tag's release before it publishes.
class ReleaseCheckTest < ReleaseChangelogCase
  # The result of the check of +tag+ against a changelog with the +unreleased+ entries, when the tags +others+ exist.
  # +released+ is the newest published release before the tag, with the entries its changelog listed.
  def check(tag, unreleased, others = [], released: nil)
    tags = others.map { |other| "#{other}\n" }
      .join
    files = { "changelog.md": changelog(unreleased), tags: }
    arguments = ["check", "@changelog.md", tag, "@tags"]
    if released
      arguments.push(released.first, "@released.md")
      files[:"released.md"] = changelog(released.last)
    end
    run_command(arguments, files)
  end

  def test_the_first_release_is_version_zero_one_zero
    status, out, = check("v0.1.0", "### Added\n\n- A command.\n")

    assert_equal(0, status)
    assert_includes(out, "v0.1.0 is the version")
  end

  def test_a_first_release_with_another_version_is_refused
    status, _, err = check("v0.2.0", "### Added\n\n- A command.\n")

    assert_equal(1, status)
    assert_includes(err, "CHANGELOG.md calls for 0.1.0, not 0.2.0")
  end

  def test_nothing_under_unreleased_is_refused
    status, _, err = check("v0.1.0", "")

    assert_equal(1, status)
    assert_includes(err, "CHANGELOG.md lists nothing new under ## [Unreleased]")
  end

  def test_a_tag_that_is_not_newer_than_every_other_tag_is_refused
    ["v0.2.0", "v0.1.5"].each do |tag|
      status, _, err = check(tag, "### Fixed\n\n- A bug.\n", ["v0.3.0", "v0.1.9", "v0.1.0"])

      assert_equal(1, status, tag)
      assert_includes(err, "#{tag} is not newer than v0.3.0, the newest release tag")
    end
  end

  def test_a_fix_or_an_addition_before_one_point_zero_raises_the_last_number
    ["### Fixed\n\n- A bug.\n", "### Added\n\n- A flag.\n"].each do |unreleased|
      status, = check("v0.1.1", unreleased, ["v0.1.0"])

      assert_equal(0, status, unreleased)
    end
  end

  def test_a_breaking_or_removed_entry_before_one_point_zero_raises_the_middle_number
    ["### Changed\n\n- **Breaking:** A rule.\n", "### Removed\n\n- A flag.\n"].each do |unreleased|
      status, _, err = check("v0.1.1", unreleased, ["v0.1.0"])

      assert_equal(1, status, unreleased)
      assert_includes(err, "calls for 0.2.0, not 0.1.1")
    end
  end

  def test_a_breaking_mark_that_does_not_start_the_entry_is_no_mark
    status, = check("v0.1.1", "### Changed\n\n- A rule. **Breaking:** no.\n", ["v0.1.0"])

    assert_equal(0, status)
  end

  def test_a_heading_that_is_not_keep_a_changelogs_is_refused
    status, _, err = check("v0.1.0", "### Breaking\n\n- A rule.\n")

    assert_equal(1, status)
    assert_includes(err, "has ### Breaking under ## [Unreleased], where the release reads only ### Added")
  end

  def test_an_entry_before_the_first_heading_is_refused
    status, _, err = check("v0.1.0", "- A rule.\n")

    assert_equal(1, status)
    assert_includes(err, "lists an entry under ## [Unreleased] before its first ### heading")
  end

  def test_a_changelog_without_an_unreleased_heading_is_refused
    files = { "changelog.md": "# Changelog\n", tags: "" }
    status, _, err = run_command(%w[check @changelog.md v0.1.0 @tags], files)

    assert_equal(1, status)
    assert_includes(err, "CHANGELOG.md has no ## [Unreleased] heading")
  end

  def test_an_entry_in_a_comment_or_a_code_fence_is_no_entry
    status, _, err = check("v0.1.0", "<!--\n- Hidden.\n-->\n\n```\n- Fenced.\n```\n")

    assert_equal(1, status)
    assert_includes(err, "lists nothing new")
  end

  def test_the_entries_of_an_unrecorded_published_release_are_not_new
    older = "### Added\n\n- A command.\n"
    status, _, err = check("v0.1.1", "#{older}\n### Fixed\n\n- A bug.\n", ["v0.1.0"], released: ["v0.1.0", older])

    assert_equal(0, status, err)
  end

  def test_nothing_new_since_an_unrecorded_published_release_is_refused
    older = "### Added\n\n- A command.\n"
    status, _, err = check("v0.1.1", older, ["v0.1.0"], released: ["v0.1.0", older])

    assert_equal(1, status)
    assert_includes(err, "lists nothing new under ## [Unreleased] since v0.1.0")
  end

  def test_a_command_line_that_is_not_check_or_record_is_a_usage_error
    status, _, err = run_command(["other"], {})

    assert_equal(2, status)
    assert_includes(err, "usage: release-changelog.rb check")
  end
end
