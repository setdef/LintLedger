# frozen_string_literal: true

require "fileutils"
require "memory_project"
require "stringio"
require "test_helper"
require "tmpdir"

class CommandLineTest < Minitest::Test
  TODOS = %(files "lib/**/*.rb"\npattern "TODO"\n)
  FIXMES = %(files "lib/**/*.rb"\npattern "FIXME"\n)
  FIXED = "x = 1 # FIXME\n\n# FIXME too\n"
  NONE = "alibi: no alibi files in .config/alibi/: add one there, or name one on the command line\n"
  private_constant(:TODOS, :FIXMES, :FIXED, :NONE)

  def setup
    @out = StringIO.new
    @err = StringIO.new
    @folder = Dir.mktmpdir("alibi-command-line-")
    @projects = MemoryProject.new(["lib/a.rb", "done\n"], ["lib/b.rb", FIXED], ["test/a.rb", "# TODO\n"])
  end

  def teardown
    FileUtils.remove_entry(@folder)
  end

  def test_version_prints_the_version_and_passes
    assert_equal(0, run_with("--version"))
    assert_equal("#{Alibi::VERSION}\n", @out.string)
    assert_empty(@err.string)
  end

  def test_an_unknown_option_is_an_error
    assert_equal(2, run_with("--bogus"))
    assert_equal("alibi: invalid option: --bogus\n", @err.string)
    assert_empty(@out.string)
  end

  def test_an_alibi_file_whose_pattern_matches_nothing_passes_and_says_what_it_checked
    write(["todos.kdl", TODOS])

    assert_equal(0, run_with("todos.kdl"))
    assert_equal("todos.kdl: passed: no matches in 2 files\n", @out.string)
    assert_empty(@err.string)
  end

  def test_an_alibi_file_whose_pattern_matches_fails_and_lists_each_match
    write(["fixmes.kdl", FIXMES])

    assert_equal(1, run_with("fixmes.kdl"))
    assert_equal(<<~OUT, @out.string)
      fixmes.kdl: failed: 2 matches in 2 files
      lib/b.rb:1: x = 1 # FIXME
      lib/b.rb:3: # FIXME too
    OUT
    assert_empty(@err.string)
  end

  def test_looks_for_the_project_from_the_folder_of_the_alibi_file
    write(["concerns/todos.kdl", TODOS])

    run_with("concerns/todos.kdl")

    assert_equal([File.join(@folder, "concerns")], @projects.folders)
  end

  def test_an_invalid_alibi_file_is_an_error_that_names_it
    write(["bad.kdl", %(files "lib/**/*.rb"\n)])

    assert_equal(2, run_with("bad.kdl"))
    assert_equal("alibi: bad.kdl: no `pattern` node: add one, with a regexp\n", @err.string)
  end

  def test_a_glob_that_matches_no_file_is_an_error_that_names_the_alibi_file_and_the_glob
    write(["typo.kdl", %(files "lib/**/*.ts"\npattern "x"\n)])

    assert_equal(2, run_with("typo.kdl"))
    assert_match(%r{\Aalibi: typo\.kdl: the glob "lib/\*\*/\*\.ts" matches no file}, @err.string)
    assert_empty(@out.string)
  end

  def test_an_error_message_shows_a_control_character_from_the_alibi_file_as_an_escape
    write(["bad.kdl", %("\\u{1b}[2J" 1\n)])

    assert_equal(2, run_with("bad.kdl"))
    assert_equal("alibi: bad.kdl: unknown node `\\x1B[2J`: an alibi file has only `files` and `pattern`\n", @err.string)
  end

  def test_with_no_alibi_file_checks_each_one_in_the_alibi_folder_by_name
    write([".config/alibi/todos.kdl", TODOS], [".config/alibi/fixmes.kdl", FIXMES], [".config/alibi/notes.txt", "x"])

    assert_equal(1, run_with)
    assert_equal(<<~OUT, @out.string)
      .config/alibi/fixmes.kdl: failed: 2 matches in 2 files
      lib/b.rb:1: x = 1 # FIXME
      lib/b.rb:3: # FIXME too
      .config/alibi/todos.kdl: passed: no matches in 2 files
    OUT
  end

  def test_an_error_in_any_alibi_file_outweighs_a_failure_and_the_rest_are_still_checked
    write(["a.kdl", FIXMES], ["b.kdl", %(files\npattern "x"\n)], ["c.kdl", TODOS])

    assert_equal(2, run_with("a.kdl", "b.kdl", "c.kdl"))
    assert_equal("alibi: b.kdl: give the `files` node one string argument and nothing else\n", @err.string)
    assert_match(/^c\.kdl: passed/, @out.string)
  end

  def test_a_failure_outweighs_a_pass
    write(["a.kdl", TODOS], ["b.kdl", FIXMES])

    assert_equal(1, run_with("a.kdl", "b.kdl"))
  end

  def test_with_no_alibi_file_and_no_alibi_folder_is_an_error
    assert_equal(2, run_with)
    assert_equal(NONE, @err.string)
  end

  private def write(*files)
    files.each do |path, text|
      FileUtils.mkdir_p(File.dirname(File.join(@folder, path)))
      File.write(File.join(@folder, path), text)
    end
  end

  private def run_with(*arguments)
    Alibi::CommandLine.new(out: @out, err: @err, folder: @folder, projects: @projects).run(arguments)
  end
end
