# frozen_string_literal: true

require "tmpdir"
require_relative("test_helper")

# SimpleCov starts in test_helper, so it must load before the code it measures.
require_relative("../tasks/shell_scripts")

# Checks that the gate finds every shell script among a project's files, by its name or by its first line.
class ShellScriptsTest < Minitest::Test
  SHELLS = [
    ["sh", "#!/bin/sh\n"],
    ["bash", "#!/bin/bash -e\n"],
    ["env", "#!/usr/bin/env bash\n"],
    ["split", "#!/usr/bin/env -S bash -eu\n"],
    ["dash", "#! /usr/bin/dash\n"],
    ["ksh", "#!/usr/bin/ksh\n"],
  ].freeze
  OTHERS = [
    ["ruby", "#!/usr/bin/env ruby\n"],
    ["shy", "#!/usr/bin/shy\n"],
    ["late", "\n#!/bin/sh\n"],
    ["empty", ""],
  ].freeze
  private_constant(:SHELLS, :OTHERS)

  # The names that ShellScripts.among picks from a folder holding +files+, each a pair of a name and a content.
  def picked(files)
    Dir.mktmpdir do |dir|
      paths = files.map do |name, content|
        path = File.join(dir, name)
        File.write(path, content)
        path
      end
      ShellScripts.among(paths).map { |path| File.basename(path) }
    end
  end

  def test_a_file_with_the_sh_extension_is_a_script
    assert_equal(["a.sh"], picked([["a.sh", "echo hi\n"], ["a.txt", "echo hi\n"]]))
  end

  def test_a_file_with_a_shell_on_its_first_line_is_a_script
    assert_equal(SHELLS.map(&:first), picked(SHELLS))
  end

  def test_a_file_with_another_interpreter_on_its_first_line_is_not_a_script
    assert_empty(picked(OTHERS))
  end

  def test_a_binary_file_is_not_a_script
    assert_empty(picked([["archive.tar.gz", "\x1F\x8B\xFF\xFE\n".b]]))
  end

  def test_a_folder_is_not_a_script
    Dir.mktmpdir { |dir| assert_empty(ShellScripts.among([dir])) }
  end
end
