# frozen_string_literal: true

require "fileutils"
require "memory_project"
require "stringio"
require "test_helper"
require "tmpdir"

class CommandLineUnreadableTest < Minitest::Test
  def setup
    @err = StringIO.new
    @folder = Dir.mktmpdir("alibi-unreadable-")
  end

  def teardown
    FileUtils.remove_entry(@folder)
  end

  def test_a_missing_alibi_file_is_an_error
    assert_equal(2, run_with("missing.kdl"))
    assert_equal("alibi: missing.kdl: can't read the alibi file: no such file or directory\n", @err.string)
  end

  def test_an_alibi_file_that_is_a_folder_is_an_error_that_says_so_without_rubys_wording
    Dir.mkdir(File.join(@folder, "folder.kdl"))

    assert_equal(2, run_with("folder.kdl"))
    assert_match(/\Aalibi: folder\.kdl: can't read the alibi file: [a-z ]+\n\z/, @err.string)
  end

  private def run_with(name)
    Alibi::CommandLine.new(out: StringIO.new, err: @err, folder: @folder, projects: MemoryProject.new).run([name])
  end
end
