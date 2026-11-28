# frozen_string_literal: true

require "test_helper"

class LinesTest < Minitest::Test
  def test_numbers_the_line_that_holds_an_offset_from_one
    lines = Alibi::Lines.new("one\ntwo\nthree")

    assert_equal([1, 1, 1, 2, 3, 3], [0, 2, 3, 4, 8, 12].map { lines.number(it) })
  end

  def test_gives_the_line_that_holds_an_offset_without_its_line_break
    lines = Alibi::Lines.new("one\ntwo\nthree")

    assert_equal(%w[one two three], [1, 5, 9].map { lines.at(it) })
  end

  def test_counts_offsets_in_bytes_not_characters
    lines = Alibi::Lines.new("é\n日本\nz")

    assert_equal([1, 2, 3], [0, 3, 10].map { lines.number(it) })
    assert_equal(%w[é 日本 z], [0, 3, 10].map { lines.at(it) })
  end

  def test_an_offset_at_the_end_of_a_text_that_ends_with_a_line_break_is_on_the_line_after_it
    lines = Alibi::Lines.new("one\n")

    assert_equal(2, lines.number(4))
    assert_equal("", lines.at(4))
  end

  def test_an_empty_text_has_one_empty_line
    lines = Alibi::Lines.new("")

    assert_equal([1, ""], [lines.number(0), lines.at(0)])
  end
end
