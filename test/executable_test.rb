# frozen_string_literal: true

require "fileutils"
require "open3"
require "rbconfig"
require "test_helper"
require "tmpdir"

# One run of exe/alibi for each exit status, in a git working tree of its own.
class ExecutableTest < Minitest::Test
  EXECUTABLE = File.expand_path("../exe/alibi", __dir__)
  LIB = File.expand_path("../lib", __dir__)
  private_constant(:EXECUTABLE, :LIB)

  def setup
    @root = Dir.mktmpdir("alibi-executable-")
    system("git", "-C", @root, "init", "--quiet", exception: true)
    write("lib/app.rb", "x = 1 # TODO\r\n")
    write("todos.kdl", %(files "lib/**/*.rb"\npattern "TODO"\n))
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def test_exits_0_when_every_alibi_file_passes
    write("fixmes.kdl", %(files "lib/**/*.rb"\npattern "FIXME"\n))

    assert_equal(["fixmes.kdl: passed: no matches in 1 file\n", "", 0], alibi("fixmes.kdl"))
  end

  def test_exits_1_when_an_alibi_file_fails
    assert_equal(["todos.kdl: failed: 1 match in 1 file\nlib/app.rb:1: x = 1 # TODO\n", "", 1], alibi("todos.kdl"))
  end

  def test_exits_2_on_an_error
    assert_equal(["", "alibi: invalid option: --bogus\n", 2], alibi("--bogus"))
  end

  private def write(path, text)
    FileUtils.mkdir_p(File.dirname(File.join(@root, path)))
    File.binwrite(File.join(@root, path), text)
  end

  private def alibi(*)
    out, err, status = Open3.capture3(RbConfig.ruby, "-I#{LIB}", EXECUTABLE, *, chdir: @root)
    [out, err, status.exitstatus]
  end
end
