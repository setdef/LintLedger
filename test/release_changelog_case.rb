# frozen_string_literal: true

require "stringio"
require "tmpdir"
require_relative("../.github/scripts/release_changelog/command")
require_relative("test_helper")

# The base of the tests of the release's changelog bookkeeping: it runs release-changelog.rb in a folder of files.
class ReleaseChangelogCase < Minitest::Test
  HEAD = <<~MARKDOWN
    # Changelog

    ## [Unreleased]

  MARKDOWN
  URL = "https://example.com/alibi"
  FOOT = <<~MARKDOWN.freeze

    [Unreleased]: #{URL}/commits/trunk
  MARKDOWN
  private_constant(:FOOT)
  public_constant(:HEAD, :URL)

  # A changelog with the +unreleased+ lines under its Unreleased heading, and the +older+ sections after them.
  def changelog(unreleased, older = "")
    "#{HEAD}#{unreleased}\n#{older}#{FOOT}"
  end

  # The status, standard output, and standard error of release-changelog.rb run with +arguments+, where each @ stands
  # for the folder that holds +files+, a hash of names and contents. The block receives the folder.
  def run_command(arguments, files)
    Dir.mktmpdir do |folder|
      files.each { |name, text| File.binwrite(File.join(folder, name.to_s), text) }
      out = StringIO.new
      err = StringIO.new
      status = ReleaseChangelog::Command.new(arguments.map { |argument| argument.sub("@", "#{folder}/") }, out, err).run
      yield(folder) if block_given?
      [status, out.string, err.string]
    end
  end
end
