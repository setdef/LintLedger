# frozen_string_literal: true

require "test_helper"

class RequestTest < Minitest::Test
  USAGE = "Usage: alibi [FILE.kdl ...] [--version] [--help]"
  private_constant(:USAGE)

  def test_version_answers_with_the_version
    assert_equal([Alibi::VERSION], Alibi::Request.new(["--version"]).answers)
  end

  def test_help_answers_with_one_usage_line
    assert_equal([USAGE], Alibi::Request.new(["--help"]).answers)
  end

  def test_both_options_answer_with_the_version_before_the_usage_line_whatever_their_order
    assert_equal([Alibi::VERSION, USAGE], Alibi::Request.new(["--help", "--version"]).answers)
  end

  def test_alibi_files_have_no_answers
    request = Alibi::Request.new(["a.kdl", "b.kdl"])

    assert_empty(request.answers)
    assert_equal(["a.kdl", "b.kdl"], request.alibi_files { ["conventional.kdl"] })
  end

  def test_with_no_alibi_file_names_the_ones_the_block_gives
    assert_equal(["conventional.kdl"], Alibi::Request.new([]).alibi_files { ["conventional.kdl"] })
  end

  def test_an_alibi_file_beside_an_option_is_an_error
    error = assert_raises(Alibi::UsageError) { Alibi::Request.new(["--version", "FILE.kdl"]).answers }

    assert_equal("--version and --help take no alibi file", error.message)
  end

  def test_an_abbreviated_option_is_an_error
    error = assert_raises(Alibi::UsageError) { Alibi::Request.new(["--vers"]) }

    assert_equal("invalid option: --vers", error.message)
  end
end
