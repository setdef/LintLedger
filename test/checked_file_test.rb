# frozen_string_literal: true

require "test_helper"

class CheckedFileTest < Minitest::Test
  TEXT = <<~RUBY
    a # TODO one
    b # TODO two # TODO three
    c = <<~TEXT # TODO four
      TEXT
    d
  RUBY
  private_constant(:TEXT)

  def test_holds_the_matches_that_start_and_end_within_some_lines
    assert_equal(["a.rb:2: b # TODO two # TODO three"] * 2, within(/TODO \w+/, 2..2))
    assert_equal(["a.rb:1: a # TODO one", "a.rb:2: b # TODO two # TODO three"], within(/TODO o|TODO tw/, 1..2))
  end

  def test_holds_no_match_that_starts_within_the_lines_and_ends_after_them
    assert_empty(within(/four\n\s+TEXT/, 3..3))
    assert_equal(["a.rb:3: c = <<~TEXT # TODO four"], within(/four\n\s+TEXT/, 3..4))
  end

  def test_holds_no_match_that_starts_before_the_lines
    assert_empty(within(/one\nb/, 2..5))
  end

  def test_holds_no_match_after_the_lines
    assert_empty(within(/TODO/, 5..5))
  end

  def test_a_match_that_ends_with_a_line_break_ends_on_the_line_the_break_ends
    assert_equal(["a.rb:1: a # TODO one"], within(/one\n/, 1..1))
  end

  def test_finds_where_a_snippet_occurs
    file = Alibi::CheckedFile.new(Alibi::SnippetIndex.new(TEXT), [])

    assert_equal([2..3], file.places(Alibi::Snippet.new("b # TODO two # TODO three\nc = <<~TEXT # TODO four")))
  end

  private def within(regexp, lines)
    file = Alibi::ProjectFile.new("a.rb", TEXT)
    Alibi::CheckedFile.new(Alibi::SnippetIndex.new(TEXT), file.matches(regexp)).matches_within(lines).map(&:to_s)
  end
end
