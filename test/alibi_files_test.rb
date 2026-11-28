# frozen_string_literal: true

require "memory_project"
require "test_helper"

# Each of the project's own alibi files in .config/alibi/ finds every form of what it bans, and nothing else. The forms
# are in test/fixtures/alibi/, in text files that no alibi file's glob matches, so the project's check never reads them:
# path.txt holds a path the glob has to match, each line of matches.txt one form the pattern has to find, and
# misses.txt lines it has to leave alone.
class AlibiFilesTest < Minitest::Test
  ALIBI_FILES = File.expand_path("../.config/alibi", __dir__)
  FIXTURES = File.expand_path("fixtures/alibi", __dir__)
  private_constant(:ALIBI_FILES, :FIXTURES)

  def test_each_alibi_file_has_fixtures
    names = Dir.glob("*.kdl", base: ALIBI_FILES).map { File.basename(it, ".kdl") }

    assert_equal(names.sort!, Dir.children(FIXTURES).sort!)
  end

  def test_each_pattern_finds_every_line_of_its_matches
    each_fixture do |name, path|
      lines = File.readlines(File.join(FIXTURES, name, "matches.txt"), chomp: true)
      expected = lines.each_with_index.map { |line, index| "#{path}:#{index + 1}: #{line}" }

      assert_equal(expected, check(name, path, "matches.txt").map(&:to_s), name)
    end
  end

  def test_each_pattern_finds_nothing_in_its_misses
    each_fixture { |name, path| assert_predicate(check(name, path, "misses.txt"), :passed?, name) }
  end

  private def each_fixture
    Dir.children(FIXTURES).each { |name| yield(name, File.read(File.join(FIXTURES, name, "path.txt")).strip) }
  end

  private def check(name, path, fixture)
    alibi_file = Alibi::AlibiFile.parse(File.binread(File.join(ALIBI_FILES, "#{name}.kdl")))
    alibi_file.check(MemoryProject.new([path, File.binread(File.join(FIXTURES, name, fixture))]))
  end
end
