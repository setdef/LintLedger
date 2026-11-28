# frozen_string_literal: true

require "alibi_check"
require "test_helper"

# Each way an alibi can fail to excuse exactly one match, with the line that says what to do about it.
class AlibiFailuresTest < Minitest::Test
  include AlibiCheck

  AMBIGUOUS = 'lib/a.rb:1: the alibi for "x # TODO" excuses no match, since its snippet occurs here and again on ' \
    "line 2: copy lines from around its match into the snippet until it occurs once"
  NONE = 'lib/a.rb:3: the alibi for "end" excuses no match, since its snippet holds none: remove it, or bring its ' \
    "snippet up to date"
  SEVERAL = 'lib/a.rb:7: the alibi for "y # TODO # TODO" excuses no match, since its snippet holds 2: cut the ' \
    "snippet down to the lines around one, or give the alibi an occurrence when they share a line"
  BEYOND = 'lib/a.rb:7: the alibi for "y # TODO # TODO" excuses no match, since its occurrence is 3 and its snippet ' \
    "holds 2: lower its occurrence"
  private_constant(:AMBIGUOUS, :NONE, :SEVERAL, :BEYOND)

  def test_an_alibi_whose_snippet_occurs_nowhere_fails
    verdict = check(alibi("z # TODO"), file: "")

    assert_equal(["lib/a.rb: the alibi for \"z # TODO\" #{STALE}"], verdict.map(&:to_s))
    assert_equal([0, 1], [verdict.matches_failed, verdict.alibis_failed])
  end

  def test_an_alibi_for_a_file_the_glob_does_not_match_fails
    verdict = check(alibi("x # TODO", path: "test/a.rb"), alibi("x # TODO", path: "lib/gone.rb"), file: "")

    assert_equal(
      ["test/a.rb: the alibi for \"x # TODO\" #{STALE}", "lib/gone.rb: the alibi for \"x # TODO\" #{STALE}"],
      verdict.map(&:to_s)
    )
  end

  def test_an_alibi_whose_snippet_occurs_more_than_once_excuses_none_of_its_places
    verdict = check(alibi("x # TODO"), file: "x # TODO\nx # TODO\nx # TODO\n")

    assert_equal(
      ["lib/a.rb:1: x # TODO", "lib/a.rb:2: x # TODO", "lib/a.rb:3: x # TODO", AMBIGUOUS],
      verdict.map(&:to_s)
    )
    assert_equal([3, 1], [verdict.matches_failed, verdict.alibis_failed])
  end

  def test_an_alibi_whose_snippet_holds_no_match_fails
    assert_equal([NONE], check(alibi("end\n\ndef b"), file: CODE.gsub("TODO", "DONE")).map(&:to_s))
  end

  def test_an_alibi_whose_snippet_holds_several_matches_and_has_no_occurrence_excuses_none_of_them
    alibis = code_alibis.take(2) << alibi("y # TODO # TODO")

    assert_equal((["lib/a.rb:7:   y # TODO # TODO"] * 2) << SEVERAL, check(*alibis).map(&:to_s))
  end

  def test_an_alibi_whose_occurrence_counts_past_the_matches_in_its_snippet_fails
    alibis = code_alibis.take(3) << alibi("y # TODO # TODO", occurrence: 3)

    assert_equal(["lib/a.rb:7:   y # TODO # TODO", BEYOND], check(*alibis).map(&:to_s))
  end

  def test_a_match_that_starts_in_the_snippet_and_ends_after_it_is_not_in_the_snippet
    alibi_file = Alibi::AlibiFile.new(
      glob: Alibi::Glob.new("lib/**/*.rb"), pattern: Alibi::Pattern.new("TODO\\n\\s*end"), alibis: [alibi("x # TODO")]
    )
    verdict = alibi_file.check(MemoryProject.new(["lib/a.rb", "x # TODO\nend\n"]))

    assert_equal(["lib/a.rb:1: x # TODO", NONE.sub(":3", ":1").sub('"end"', '"x # TODO"')], verdict.map(&:to_s))
  end
end
