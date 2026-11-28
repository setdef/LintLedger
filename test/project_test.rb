# frozen_string_literal: true

require "fileutils"
require "test_helper"
require "tmpdir"

# The only tests besides ExecutableTest that start git, so they share one working tree, built once.
class ProjectTest < Minitest::Test
  ROOT = File.realpath(Dir.mktmpdir("alibi-project-"))
  private_constant(:ROOT)

  Minitest.after_run { FileUtils.remove_entry(ROOT) }

  def self.write(root, files)
    files.each do |path, text|
      FileUtils.mkdir_p(File.dirname(File.join(root, path)))
      File.binwrite(File.join(root, path), text)
    end
  end

  system("git", "-C", ROOT, "init", "--quiet", exception: true)
  write(
    ROOT,
    [[".gitignore", "/build/\n"], ["lib/tracked.rb", "1\n"], ["lib/deleted.rb", "2\n"], ["docs/a café.md", "3\n"]]
  )
  system("git", "-C", ROOT, "add", ".", exception: true)
  File.delete(File.join(ROOT, "lib/deleted.rb"))
  write(ROOT, [["lib/untracked.rb", "4\r\n"], ["build/output.rb", "5\n"]])
  File.symlink("tracked.rb", File.join(ROOT, "lib/link.rb"))

  # A checkout's own config can name a command for git to run, and a clone is untrusted.
  # This one names a command that leaves a marker.
  FSMONITOR_ROOT = File.realpath(Dir.mktmpdir("alibi-fsmonitor-"))
  FSMONITOR_MARKER = File.join(FSMONITOR_ROOT, "marker")
  private_constant(:FSMONITOR_ROOT, :FSMONITOR_MARKER)

  Minitest.after_run { FileUtils.remove_entry(FSMONITOR_ROOT) }

  system("git", "-C", FSMONITOR_ROOT, "init", "--quiet", exception: true)
  write(FSMONITOR_ROOT, [["lib/tracked.rb", "1\n"]])
  system("git", "-C", FSMONITOR_ROOT, "add", ".", exception: true)
  File.write(File.join(FSMONITOR_ROOT, ".git/config"), <<~CONFIG, mode: "a")
    [core]
    \tfsmonitor = echo ran >'#{FSMONITOR_MARKER}'; :
  CONFIG

  # An unresolved merge conflict leaves a path in three stages of the index, and git lists it once for each.
  CONFLICT_ROOT = File.realpath(Dir.mktmpdir("alibi-conflict-"))
  private_constant(:CONFLICT_ROOT)

  Minitest.after_run { FileUtils.remove_entry(CONFLICT_ROOT) }

  def self.git(*, **)
    system("git", "-C", CONFLICT_ROOT, "-c", "user.name=Test", "-c", "user.email=test@example.com", *, **)
  end

  def self.commit(text)
    write(CONFLICT_ROOT, [["conflict.txt", text]])
    git("add", ".", exception: true)
    git("commit", "--quiet", "-m", "x", exception: true)
  end

  git("init", "--quiet", exception: true)
  commit("base\n")
  git("switch", "--quiet", "--create", "other", exception: true)
  commit("other\n")
  git("switch", "--quiet", "-", exception: true)
  commit("mine\n")
  # The merge stops on the conflict, which is the state the test needs.
  git("merge", "--quiet", "other", out: File::NULL, err: File::NULL)

  def test_a_path_with_an_unresolved_merge_conflict_is_listed_once
    assert_equal(["conflict.txt"], Alibi::Project.containing(CONFLICT_ROOT).paths)
  end

  def test_runs_no_command_that_the_checkouts_own_config_names
    Alibi::Project.containing(File.join(FSMONITOR_ROOT, "lib")).paths

    refute_path_exists(FSMONITOR_MARKER)
  end

  def test_finds_the_top_of_the_working_tree_from_a_folder_inside_it
    assert_includes(Alibi::Project.containing(File.join(ROOT, "lib")).paths, "docs/a café.md")
  end

  def test_lists_tracked_and_untracked_files_but_not_ignored_deleted_or_linked_ones
    assert_equal(
      [".gitignore", "docs/a café.md", "lib/tracked.rb", "lib/untracked.rb"],
      Alibi::Project.containing(ROOT).paths.sort
    )
  end

  def test_a_root_that_git_can_not_list_is_an_error_instead_of_a_project_with_no_files
    root = File.join(ROOT, "gone")

    error = assert_raises(Alibi::Error) { Alibi::Project.new(root).paths }

    assert_match(/\Agit couldn't list the files of #{Regexp.escape(root)}: .*gone/, error.message)
  end

  def test_reads_a_file_by_its_path_from_the_root
    file = Alibi::Project.containing(File.join(ROOT, "docs")).file("lib/untracked.rb")

    assert_equal(["lib/untracked.rb:1: 4"], file.matches(/4$/).map(&:to_s))
  end

  def test_a_folder_outside_any_working_tree_is_an_error
    Dir.mktmpdir("alibi-not-git-") do |folder|
      # The temporary folder may sit inside a working tree. A .git file that
      # points nowhere makes git stop at the folder, as it would at the top.
      File.write(File.join(folder, ".git"), "gitdir: #{File.join(folder, 'nowhere')}\n")

      error = assert_raises(Alibi::Error) { Alibi::Project.containing(folder) }

      assert_equal(
        "#{folder} isn't inside a git working tree: keep the alibi file in the project it checks",
        error.message
      )
    end
  end
end
