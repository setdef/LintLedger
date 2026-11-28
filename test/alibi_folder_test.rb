# frozen_string_literal: true

require "fileutils"
require "test_helper"
require "tmpdir"

class AlibiFolderTest < Minitest::Test
  NONE = "no alibi files in .config/alibi/: add one there, or name one on the command line"
  private_constant(:NONE)

  def setup
    @folder = Dir.mktmpdir("alibi-folder-")
    FileUtils.mkdir_p(File.join(@folder, ".config/alibi/deeper"))
  end

  def teardown
    FileUtils.remove_entry(@folder)
  end

  def test_names_each_kdl_file_directly_in_the_folder_in_order_of_name
    %w[b.kdl a.kdl notes.txt deeper/c.kdl].each { |name| FileUtils.touch(File.join(@folder, ".config/alibi", name)) }

    assert_equal([".config/alibi/a.kdl", ".config/alibi/b.kdl"], Alibi::AlibiFolder.new(@folder).names)
  end

  def test_a_folder_with_no_kdl_file_is_an_error
    error = assert_raises(Alibi::Error) { Alibi::AlibiFolder.new(@folder).names }

    assert_equal(NONE, error.message)
  end

  def test_a_missing_folder_is_an_error
    FileUtils.remove_entry(File.join(@folder, ".config"))

    error = assert_raises(Alibi::Error) { Alibi::AlibiFolder.new(@folder).names }

    assert_equal(NONE, error.message)
  end
end
