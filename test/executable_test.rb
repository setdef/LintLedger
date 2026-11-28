# frozen_string_literal: true

require "test_helper"
require "open3"
require "rbconfig"

class ExecutableTest < Minitest::Test
  EXECUTABLE = File.expand_path("../exe/alibi", __dir__)
  LIB = File.expand_path("../lib", __dir__)
  private_constant(:EXECUTABLE, :LIB)

  def test_exits_with_the_status_of_the_command_line
    out, err, status = alibi("--version")

    assert_equal("#{Alibi::VERSION}\n", out)
    assert_empty(err)
    assert_equal(0, status.exitstatus)
  end

  def test_exits_2_on_an_error
    out, err, status = alibi("--bogus")

    assert_empty(out)
    assert_equal("alibi: invalid option: --bogus\n", err)
    assert_equal(2, status.exitstatus)
  end

  private

  def alibi(*arguments)
    Open3.capture3(RbConfig.ruby, "-I#{LIB}", EXECUTABLE, *arguments)
  end
end
