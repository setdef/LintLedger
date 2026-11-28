# frozen_string_literal: true

require "test_helper"

class EscapedTest < Minitest::Test
  def test_leaves_plain_text_and_a_tab_alone
    assert_equal("café\tdone", escaped("café\tdone"))
  end

  def test_shows_a_c0_control_character_as_an_escape
    assert_equal("\\x1B[2J\\x07\\x0D\\x7F", escaped("\e[2J\a\r\x7F"))
  end

  def test_shows_a_line_break_and_the_edges_of_each_control_range_as_escapes
    assert_equal("a\\x0Ab\\x08\\x1F\\xC2\\x80\\xC2\\x9F\u00A0", escaped("a\nb\b\u001F\u0080\u009F\u00A0"))
  end

  def test_shows_a_c1_control_character_as_the_escapes_of_its_bytes
    assert_equal("a\\xC2\\x9B2Jb", escaped("a\u009B2Jb"))
  end

  def test_shows_a_bidirectional_override_or_isolate_as_the_escapes_of_its_bytes
    assert_equal("\\xE2\\x80\\xAA\\xE2\\x80\\xAE\\xE2\\x81\\xA6\\xE2\\x81\\xA9", escaped("\u202A\u202E\u2066\u2069"))
  end

  def test_shows_the_line_and_paragraph_separators_as_the_escapes_of_their_bytes
    assert_equal("a\\xE2\\x80\\xA8b\\xE2\\x80\\xA9c", escaped("a\u2028b\u2029c"))
  end

  def test_leaves_the_characters_beside_those_ranges_alone
    assert_equal("\u2027\u202F\u2065\u206A", escaped("\u2027\u202F\u2065\u206A"))
  end

  def test_shows_a_byte_that_is_not_utf8_as_an_escape
    assert_equal("bad\\xFFname", escaped("bad\xFFname"))
  end

  private def escaped(text)
    Alibi::Escaped.new(text).to_s
  end
end
