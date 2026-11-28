# frozen_string_literal: true

require "stringio"
require "test_helper"

class ReportTest < Minitest::Test
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

  private def match(path, line, text)
    Alibi::Match.new(path:, line:, text:)
  end

  private def report(verdict)
    Alibi::Report.new("todos.kdl", verdict).write(@out)
  end
end
