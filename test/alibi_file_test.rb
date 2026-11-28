# frozen_string_literal: true

require "memory_project"
require "test_helper"

class AlibiFileTest < Minitest::Test
  TODOS = <<~KDL
    // Every TODO waits on an issue instead.
    files "lib/**/*.rb"
    pattern #"TODO\\b"#
  KDL
  private_constant(:TODOS)

  def test_passes_when_the_pattern_matches_nothing_in_the_files_its_glob_matches
    verdict = check(["lib/a.rb", "done\n"], ["lib/b/c.rb", "done\n"], ["test/a.rb", "# TODO\n"])

    assert_predicate(verdict, :passed?)
    assert_equal(2, verdict.files_checked)
    assert_empty(verdict.to_a)
  end

  def test_fails_with_every_match_in_the_files_its_glob_matches
    verdict = check(["lib/a.rb", "# TODO one\n# TODO two\n"], ["lib/b.rb", "done\n"], ["lib/c.rb", "x # TODO\n"])

    refute_predicate(verdict, :passed?)
    assert_equal(3, verdict.files_checked)
    assert_equal(["lib/a.rb:1: # TODO one", "lib/a.rb:2: # TODO two", "lib/c.rb:1: x # TODO"], verdict.map(&:to_s))
  end

  def test_reads_no_file_its_glob_does_not_match
    assert_predicate(check(["lib/a.rb", "done\n"], ["logo.png", "\xFF".b]), :passed?)
  end

  def test_passes_when_its_glob_matches_no_file
    verdict = check

    assert_predicate(verdict, :passed?)
    assert_equal(0, verdict.files_checked)
  end

  def test_keeps_the_line_and_column_of_a_kdl_syntax_error
    error = assert_raises(Alibi::Error) { Alibi::AlibiFile.parse(%(files "lib/**/*.rb\npattern "x"\n)) }

    assert_match(/\(1:\d+\)\z/, error.message)
  end

  def test_reads_bytes_as_utf8
    alibi_file = Alibi::AlibiFile.parse(%(files "docs/café/*.md"\npattern "é"\n).b)

    assert_equal(["docs/café/a.md:1: é"], alibi_file.check(MemoryProject.new(["docs/café/a.md", "é\n"])).map(&:to_s))
  end

  def test_an_alibi_file_that_is_not_utf8_is_an_error
    assert_error("the alibi file isn't UTF-8 text", %(files "\xFF"\npattern "x"\n).b)
  end

  def test_reads_kdl2_and_never_falls_back_to_kdl1
    assert_raises(Alibi::Error) { Alibi::AlibiFile.parse(%(files r"lib/*.rb"\npattern "x"\n)) }
  end

  def test_without_files_is_an_error
    assert_error("no `files` node: add one, with the glob of the files to check", %(pattern "x"\n))
  end

  def test_without_a_pattern_is_an_error
    assert_error("no `pattern` node: add one, with a regexp", %(files "*"\n))
  end

  def test_a_second_files_node_is_an_error
    assert_error("more than one `files` node: keep one", %(files "a"\nfiles "b"\npattern "x"\n))
  end

  def test_a_second_pattern_node_is_an_error
    assert_error("more than one `pattern` node: keep one", %(files "a"\npattern "x"\npattern "y"\n))
  end

  def test_an_unknown_node_is_an_error
    assert_error(
      "unknown node `glob`: an alibi file has only `files` and `pattern`",
      %(glob "a"\nfiles "a"\npattern "x"\n)
    )
  end

  def test_an_alibi_is_an_error_until_alibi_reads_them
    assert_error(
      "an `alibi` node: this version of Alibi doesn't read alibis yet",
      %(files "a"\npattern "x"\nalibi "a" {\n  reason "r"\n}\n)
    )
  end

  def test_a_node_needs_exactly_one_string_argument
    [%(files\n), %(files "a" "b"\n), %(files 1\n), %(files #true\n), %(files (glob)"a"\n)].each do |line|
      assert_error("give the `files` node one string argument and nothing else", "#{line}pattern \"x\"\n")
    end
  end

  def test_a_property_is_an_error
    assert_error("give the `pattern` node one string argument and nothing else", %(files "a"\npattern "x" flags="i"\n))
  end

  def test_a_child_node_is_an_error
    assert_error("give the `pattern` node one string argument and nothing else", %(files "a"\npattern "x" {\n  i\n}\n))
  end

  def test_a_type_annotation_on_a_node_is_an_error
    assert_error("give the `files` node one string argument and nothing else", %((glob)files "a"\npattern "x"\n))
  end

  def test_a_glob_or_pattern_error_comes_through
    assert_raises(Alibi::Error) { Alibi::AlibiFile.parse(%(files "/etc/*"\npattern "x"\n)) }
    assert_raises(Alibi::Error) { Alibi::AlibiFile.parse(%(files "*"\npattern "(a)\\\\1"\n)) }
  end

  private def check(*files)
    Alibi::AlibiFile.parse(TODOS).check(MemoryProject.new(*files))
  end

  private def assert_error(message, source)
    error = assert_raises(Alibi::Error) { Alibi::AlibiFile.parse(source) }

    assert_equal(message, error.message)
  end
end
