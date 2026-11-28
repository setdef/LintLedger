# frozen_string_literal: true

require "test_helper"

class EscapedTest < Minitest::Test
  def test_leaves_plain_text_and_a_tab_alone
    assert_equal("café\tdone", escaped("café\tdone"))
  end

  def test_shows_a_c0_control_character_as_an_escape
    assert_equal("\\x1B[2J\\x07\\x0D\\x7F", escaped("\e[2J\a\r\x7F"))
  end

  def test_shows_a_c1_control_character_as_the_escapes_of_its_bytes
    assert_equal("a\\xC2\\x9B2Jb", escaped("a\u009B2Jb"))
  end

  def test_shows_a_byte_that_is_not_utf8_as_an_escape
    assert_equal("bad\\xFFname", escaped("bad\xFFname"))
  end

  private def escaped(text)
    Alibi::Escaped.new(text).to_s
  end
end
