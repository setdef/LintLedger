# frozen_string_literal: true

require "test_helper"
require "timeout"

class SnippetTest < Minitest::Test
  FILE = <<~RUBY
    def a
      x = 1 # TODO
    end

    def b
      x = 1 # TODO
      y = 2
    end
  RUBY
  private_constant(:FILE)

  def test_finds_the_lines_a_snippet_covers
    assert_equal([6..7], places("x = 1 # TODO\ny = 2"))
  end

  def test_ignores_leading_whitespace_in_the_snippet_and_the_file
    assert_equal([6..7], places("        x = 1 # TODO\n\t  y = 2\n"))
  end

  def test_keeps_trailing_whitespace
    assert_empty(places("y = 2 "))
  end

  def test_finds_nothing_where_the_snippet_does_not_occur
    assert_empty(places("x = 1 # TODO\nz = 3"))
  end

  def test_finds_nothing_for_a_snippet_longer_than_the_file
    assert_empty(Alibi::Snippet.new("a\nb\nc").places_in(Alibi::SnippetIndex.new("a\nb\n")))
  end

  def test_an_index_finds_no_place_for_no_lines
    assert_empty(Alibi::SnippetIndex.new(FILE).places([]))
  end

  def test_finds_the_first_two_places_of_a_snippet_that_occurs_more_than_once
    assert_equal([2..2, 6..6], places("x = 1 # TODO"))
    assert_equal([1..2, 2..3], Alibi::Snippet.new("a\na").places_in(Alibi::SnippetIndex.new("a\na\na\na\n")))
  end

  def test_tells_lines_apart_that_differ_only_after_their_first_line
    assert_equal([3..4], Alibi::Snippet.new("a\nc").places_in(Alibi::SnippetIndex.new("a\nb\na\nc\na\nd\n")))
  end

  def test_compares_snippets_of_different_lengths_in_one_file
    index = Alibi::SnippetIndex.new(FILE)

    assert_equal(
      [[1..1], [2..3], [6..8]],
      ["def a", "x = 1 # TODO\nend", "x = 1 # TODO\ny = 2\nend"].map do |text|
        Alibi::Snippet.new(text).places_in(index)
      end
    )
  end

  def test_reads_a_crlf_snippet_as_lf
    assert_equal([6..7], places("x = 1 # TODO\r\ny = 2\r\n"))
  end

  def test_an_empty_snippet_is_an_error
    error = assert_raises(Alibi::Error) { Alibi::Snippet.new("") }

    assert_equal("an empty snippet: copy into it the lines that hold the alibi's match", error.message)
  end

  def test_shows_its_first_line_quoted_without_its_indent
    assert_equal('"x = 1 # TODO"', Alibi::Snippet.new("  x = 1 # TODO\n  y = 2").to_s)
  end

  def test_finds_ten_thousand_snippets_in_a_file_of_ten_thousand_lines_in_linear_time
    lines = Array.new(10_000) { "  x = #{it} # TODO\n" }
    index = Alibi::SnippetIndex.new(lines.join)

    found = Timeout.timeout(2) do
      Array.new(10_000) { Alibi::Snippet.new("x = #{it} # TODO").places_in(index) }
    end

    assert_equal([[1..1], [10_000..10_000]], [found.first, found.last])
  end

  private def places(text)
    Alibi::Snippet.new(text).places_in(Alibi::SnippetIndex.new(FILE))
  end
end
