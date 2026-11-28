# frozen_string_literal: true

require "test_helper"
require "timeout"

class ProjectFileTest < Minitest::Test
  def test_finds_each_match_of_a_regexp_with_its_path_line_and_text
    file = Alibi::ProjectFile.new("lib/a.rb", "one\ntwo\nthree")

    assert_equal(["lib/a.rb:1: one", "lib/a.rb:3: three"], matches(file, /one|three/))
  end

  def test_finds_two_matches_on_one_line
    assert_equal(["a.rb:1: a TODO b TODO"] * 2, matches(Alibi::ProjectFile.new("a.rb", "a TODO b TODO\n"), /TODO/))
  end

  def test_a_match_that_starts_on_a_line_break_is_on_the_line_the_break_ends
    assert_equal(["a.rb:1: one"], matches(Alibi::ProjectFile.new("a.rb", "one\ntwo"), /\nt/))
  end

  def test_a_match_at_the_very_end_is_on_the_line_after_the_last_line_break
    assert_equal(["a.rb:2: "], matches(Alibi::ProjectFile.new("a.rb", "one\n"), /\z/))
  end

  def test_finds_the_line_of_a_match_after_multibyte_text
    file = Alibi::ProjectFile.new("a.md", "café\n日本語 é\nlast é")

    assert_equal(["a.md:1: café", "a.md:2: 日本語 é", "a.md:3: last é"], matches(file, /é$/))
    assert_equal(["a.md:2: 日本語 é"], matches(file, /語/))
  end

  def test_finds_a_hundred_thousand_matches_in_linear_time
    file = Alibi::ProjectFile.new("big.txt", "a\n" * 100_000)

    found = Timeout.timeout(2) { matches(file, /a/) }

    assert_equal(["big.txt:1: a", "big.txt:100000: a"], [found.first, found.last])
  end

  def test_reads_bytes_as_utf8
    file = Alibi::ProjectFile.new("docs/café.md", "caf\xC3\xA9\n".b)

    assert_equal(["docs/café.md:1: café"], matches(file, /é/))
  end

  def test_turns_each_crlf_into_lf
    file = Alibi::ProjectFile.new("a.txt", "a\r\nb\r\nc\rd\r\n")

    assert_equal(["a.txt:3: c\rd"], matches(file, /\r/))
    assert_equal(["a.txt:1: a", "a.txt:2: b"], matches(file, /^[ab]$/))
  end

  def test_a_file_that_is_not_utf8_is_an_error
    error = assert_raises(Alibi::Error) { Alibi::ProjectFile.new("logo.png", "\x89PNG\r\n\xFF".b) }

    assert_equal("logo.png isn't UTF-8 text: list only text files in the glob", error.message)
  end

  def test_a_match_that_runs_past_the_timeout_is_an_error
    file = Alibi::ProjectFile.new("big.txt", "#{'ab' * 500_000}x")

    error = assert_raises(Alibi::Error) { file.matches(Regexp.new("\\A(?:a|b)*\\z", timeout: 0.000_001)) }

    assert_equal("the pattern ran for more than 1.0e-06 seconds over big.txt", error.message)
  end

  def test_indexes_its_lines_for_snippets_as_it_matches_them_with_crlf_as_lf
    index = Alibi::ProjectFile.new("a.txt", "a\r\n  b\r\n".b).snippet_index

    assert_equal([1], index.places(%w[a b]))
  end

  private def matches(file, regexp)
    file.matches(regexp).map(&:to_s)
  end
end
