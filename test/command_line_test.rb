# frozen_string_literal: true

require "test_helper"
require "stringio"

class CommandLineTest < Minitest::Test
  def setup
    @out = StringIO.new
    @err = StringIO.new
  end

  def test_version_prints_the_version_and_passes
    assert_equal(0, run_with("--version"))
    assert_equal("#{Alibi::VERSION}\n", @out.string)
    assert_empty(@err.string)
  end

  def test_help_prints_one_usage_line_and_passes
    assert_equal(0, run_with("--help"))
    assert_equal("Usage: alibi [--version] [--help]\n", @out.string)
    assert_empty(@err.string)
  end

  def test_no_arguments_is_an_error
    assert_equal(2, run_with)
    assert_equal("alibi: expected --version or --help\n", @err.string)
    assert_empty(@out.string)
  end

  def test_an_unknown_option_is_an_error
    assert_equal(2, run_with("--bogus"))
    assert_equal("alibi: invalid option: --bogus\n", @err.string)
    assert_empty(@out.string)
  end

  def test_an_unexpected_argument_is_an_error
    assert_equal(2, run_with("--version", "FILE.kdl"))
    assert_equal("alibi: expected --version or --help\n", @err.string)
    assert_empty(@out.string)
  end

  private

  def run_with(*arguments)
    Alibi::CommandLine.new(out: @out, err: @err).run(arguments)
  end
end
