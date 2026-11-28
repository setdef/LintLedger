# frozen_string_literal: true

require "test_helper"

# Checks that a Ruby warning about this project's own code fails the run, and that a warning about anything else does not.
class ProjectWarningsTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  UNUSED = "warning: assigned but unused variable - unused\n"
  private_constant(:ROOT, :UNUSED)

  def test_raises_on_a_warning_about_a_file_in_lib
    error = assert_raises(ProjectWarnings::Fault) { Warning.warn("#{ROOT}/lib/alibi.rb:3: #{UNUSED}") }

    assert_equal("#{ROOT}/lib/alibi.rb:3: #{UNUSED}", error.message)
  end

  def test_raises_on_a_warning_about_a_file_given_by_a_relative_path
    assert_raises(ProjectWarnings::Fault) { Warning.warn("lib/alibi.rb:3: #{UNUSED}") }
  end

  def test_raises_on_a_warning_about_a_file_in_the_tasks_or_the_tests
    assert_raises(ProjectWarnings::Fault) { Warning.warn("#{ROOT}/tasks/steep.rake:1: #{UNUSED}") }
    assert_raises(ProjectWarnings::Fault) { Warning.warn("#{ROOT}/test/command_line_test.rb:1: #{UNUSED}") }
  end

  def test_raises_on_the_warning_that_ruby_gives_while_it_compiles_a_file_of_the_project
    assert_raises(ProjectWarnings::Fault) { evaluate_verbosely("def planted\n  unused = 1\nend\n", "#{ROOT}/lib/alibi/planted.rb") }
  end

  def test_passes_on_a_warning_about_a_gem
    assert_warned("#{ROOT}/vendor/bundle/gems/x/lib/x.rb:1: #{UNUSED}")
    assert_warned("/elsewhere/gems/x/lib/x.rb:1: #{UNUSED}")
  end

  def test_passes_on_a_warning_about_the_folders_that_rubocop_leaves_out
    assert_warned("#{ROOT}/tmp/rdoc/x.rb:1: #{UNUSED}")
    assert_warned("#{ROOT}/coverage/x.rb:1: #{UNUSED}")
  end

  def test_passes_on_a_warning_that_names_no_file
    assert_warned("warning: something with no file\n")
  end

  def test_passes_on_a_warning_about_a_folder_that_only_starts_like_the_project
    assert_warned("#{ROOT}-other/lib/x.rb:1: #{UNUSED}")
  end

  private def evaluate_verbosely(source, path)
    verbose = $VERBOSE
    $VERBOSE = true
    Object.new.instance_eval(source, path, 1)
  ensure
    $VERBOSE = verbose
  end

  private def assert_warned(message)
    _out, err = capture_io { Warning.warn(message) }

    assert_equal(message, err)
  end
end
