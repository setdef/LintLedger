# frozen_string_literal: true

require "alibi_check"
require "test_helper"
require "timeout"

# An alibi file's alibis, checked against a project in both directions: every match has exactly one alibi, and every
# alibi excuses exactly one match.
class AlibisTest < Minitest::Test
  include AlibiCheck

  def test_passes_when_each_match_has_exactly_one_alibi
    verdict = check(*code_alibis)

    assert_predicate(verdict, :passed?)
    assert_empty(verdict.to_a)
    assert_equal(4, verdict.matches_found)
  end

  def test_compares_each_line_without_its_leading_whitespace
    assert_predicate(check(alibi("def a\n    x # TODO"), file: "  def a\nx # TODO\n"), :passed?)
  end

  def test_a_match_no_alibi_excuses_fails_as_it_does_without_alibis
    verdict = check(alibi("x # TODO\nend"), file: "x # TODO\nend\n\nx # TODO\n")

    assert_equal(["lib/a.rb:4: x # TODO"], verdict.map(&:to_s))
    assert_equal([1, 0], [verdict.matches_failed, verdict.alibis_failed])
  end

  def test_two_alibis_that_excuse_one_match_fail_on_that_match
    verdict = check(alibi("def a\nx # TODO"), *code_alibis)

    assert_equal(["lib/a.rb:2: 2 alibis excuse this match: keep one:   x # TODO"], verdict.map(&:to_s))
    assert_equal([1, 0], [verdict.matches_failed, verdict.alibis_failed])
  end

  def test_an_occurrence_counts_from_one
    error = assert_raises(Alibi::Error) { alibi("x # TODO", occurrence: 0) }

    assert_equal("the alibi for \"x # TODO\" has occurrence 0: count the matches in its snippet from 1", error.message)
  end

  def test_pairs_ten_thousand_alibis_with_ten_thousand_matches_in_one_file_in_linear_time
    lines = Array.new(10_000) { "x = #{it} # TODO\n" }
    alibis = Array.new(10_000) { alibi("x = #{it} # TODO") }

    verdict = Timeout.timeout(2) { check(*alibis, file: lines.join) }

    assert_predicate(verdict, :passed?)
  end
end
