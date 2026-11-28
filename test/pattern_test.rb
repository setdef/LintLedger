# frozen_string_literal: true

require "test_helper"

class PatternTest < Minitest::Test
  def test_finds_each_match_with_its_line
    assert_equal(
      ["app.rb:1: x = 1 # TODO", "app.rb:3: z = 3 # TODO: later"],
      matches("TODO", "x = 1 # TODO\ny = 2\nz = 3 # TODO: later\n")
    )
  end

  def test_finds_nothing_in_a_file_without_a_match
    assert_empty(matches("TODO", "done\n"))
  end

  def test_a_match_can_span_lines_and_is_on_the_line_where_it_starts
    assert_equal(["app.rb:2: begin"], matches("begin\\nrescue", "a\nbegin\nrescue\nend\n"))
  end

  def test_a_pattern_spans_a_crlf_line_break_as_it_spans_lf
    assert_equal(["app.rb:1: begin"], matches("begin\\nrescue", "begin\r\nrescue\r\n"))
  end

  def test_lookaround_is_allowed
    assert_equal(["app.rb:2: deny(y)"], matches("(?<=deny)\\(", "allow(x)\ndeny(y)\n"))
  end

  def test_an_invalid_regexp_is_an_error
    error = assert_raises(Alibi::Error) { Alibi::Pattern.new("TO(DO") }

    assert_match(/\Athe pattern isn't a valid Ruby regexp: /, error.message)
  end

  def test_a_regexp_that_ruby_cannot_match_in_linear_time_is_an_error
    error = assert_raises(Alibi::Error) { Alibi::Pattern.new("(a)\\1") }

    assert_equal(
      "Ruby can't match the pattern /(a)\\1/ in linear time, so it could hang Alibi: remove its back-references, " \
        "captures inside lookarounds, nested quantifiers, absence operators, and conditionals",
      error.message
    )
  end

  def test_stops_after_its_timeout
    pattern = Alibi::Pattern.new("\\A(?:a|b)*\\z", timeout: 0.000_001)

    assert_raises(Alibi::Error) { pattern.matches(Alibi::ProjectFile.new("big.txt", "#{'ab' * 500_000}x")) }
  end

  def test_shows_as_a_regexp_literal
    assert_equal("/TODO:/", Alibi::Pattern.new("TODO:").to_s)
  end

  private def matches(source, text)
    Alibi::Pattern.new(source).matches(Alibi::ProjectFile.new("app.rb", text)).map(&:to_s)
  end
end
