# frozen_string_literal: true

require "stringio"
require "test_helper"

class ReportTest < Minitest::Test
  FAILED = <<~OUT
    todos.kdl: failed: 2 matches and 2 alibis in 1 file
    a.rb:2: 2 alibis excuse this match: keep one: TODO
    a.rb:3: TODO
    a.rb: the alibi for "x" matches nothing
    a.rb:9: the alibi for "y" excuses no match
  OUT
  private_constant(:FAILED)

  def setup
    @out = StringIO.new
  end

  def test_a_pass_says_how_many_files_alibi_checked
    report(Alibi::Verdict.new(paths: Array.new(14) { "lib/#{it}.rb" }, matches: []))

    assert_equal("todos.kdl: passed: no matches in 14 files\n", @out.string)
  end

  def test_a_failure_lists_each_match_by_path_and_line
    matches = [match("lib/a.rb", 3, "# TODO"), match("lib/b.rb", 1, "x # TODO")]
    report(Alibi::Verdict.new(paths: ["lib/a.rb", "lib/b.rb"], matches:))

    assert_equal("todos.kdl: failed: 2 matches in 2 files\nlib/a.rb:3: # TODO\nlib/b.rb:1: x # TODO\n", @out.string)
  end

  def test_counts_one_file_and_one_match_in_the_singular
    report(Alibi::Verdict.new(paths: ["a.rb"], matches: [match("a.rb", 1, "TODO")]))

    assert_equal("todos.kdl: failed: 1 match in 1 file\n", @out.string.lines.first)
  end

  def test_shows_control_characters_from_a_project_file_as_escapes
    report(Alibi::Verdict.new(paths: ["a.rb"], matches: [match("a\e[2J.rb", 1, "TODO \e]0;title\a\tdone\r")]))

    assert_equal("a\\x1B[2J.rb:1: TODO \\x1B]0;title\\x07\tdone\\x0D\n", @out.string.lines.last)
  end

  def test_shows_control_characters_in_the_name_of_the_alibi_file_as_escapes
    Alibi::Report.new("a\e]0;x\a.kdl", Alibi::Verdict.new(paths: [], matches: [])).write(@out)

    assert_equal("a\\x1B]0;x\\x07.kdl: passed: no matches in 0 files\n", @out.string)
  end

  def test_shows_a_path_that_is_not_utf8_instead_of_crashing
    report(Alibi::Verdict.new(paths: ["a"], matches: [match("bad\xFFname", 1, "TODO\u009B")]))

    assert_equal("bad\\xFFname:1: TODO\\xC2\\x9B\n", @out.string.lines.last)
  end

  def test_a_pass_with_alibis_says_how_many_matches_they_excuse
    matches = [match("a.rb", 1, "TODO"), match("a.rb", 2, "TODO")]
    report(Alibi::Verdict.new(paths: ["a.rb"], matches:, excused: matches))

    assert_equal("todos.kdl: passed: 2 matches in 1 file, each with its alibi\n", @out.string)
  end

  def test_a_failure_counts_the_matches_and_the_alibis_that_fail_and_lists_each
    matches = [1, 2, 3].map { match("a.rb", it, "TODO") }
    once, twice = matches
    failures = ['a.rb: the alibi for "x" matches nothing', 'a.rb:9: the alibi for "y" excuses no match']
    report(Alibi::Verdict.new(paths: ["a.rb"], matches:, excused: [once, twice, twice], failures:))

    assert_equal(FAILED, @out.string)
  end

  def test_a_failure_of_alibis_alone_counts_only_them
    report(Alibi::Verdict.new(paths: ["a.rb"], matches: [], failures: ["a.rb: \"x\e[2J\" matches nothing"]))

    assert_equal("todos.kdl: failed: 1 alibi in 1 file\na.rb: \"x\\x1B[2J\" matches nothing\n", @out.string)
  end

  private def match(path, line, text)
    Alibi::Match.new(path:, line:, text:)
  end

  private def report(verdict)
    Alibi::Report.new("todos.kdl", verdict).write(@out)
  end
end
