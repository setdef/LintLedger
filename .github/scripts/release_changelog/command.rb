# frozen_string_literal: true

require "time"
require_relative "changelog"
require_relative "check"
require_relative "news"
require_relative "recorded_changelog"
require_relative "release_record"

module ReleaseChangelog
  # The command line of release-changelog.rb. Its first argument is `check` or
  # `record`, and its status is 0 for success, 1 for a problem, 2 for a usage
  # mistake, and 3 when `record` finds the release recorded already.
  class Command
    USAGE = <<~USAGE
      usage: release-changelog.rb check CHANGELOG TAG TAGS_FILE [RELEASED_TAG RELEASED_CHANGELOG]
             release-changelog.rb record CHANGELOG TRUNK_CHANGELOG TAG DATE REPOSITORY_URL [RELEASED_TAG RELEASED_CHANGELOG]
    USAGE
    private_constant(:USAGE)

    # A command line of +argv+, which writes to the +out+ and +err+ streams.
    def initialize(argv, out, err)
      @argv = argv.dup
      @out = out
      @err = err
    end

    # Runs the command, and returns its status.
    def run
      case @argv.shift
      when "check" then check
      when "record" then record
      else usage
      end
    end

    private def check
      changelog, tag, tags, *released = @argv
      return usage unless tags

      others = read(tags).split - [tag]
      problem = Check.new(tag:, other_tags: others, news: news(changelog, released)).problem
      problem ? fail_with(problem) : succeed("#{tag} is the version CHANGELOG.md calls for")
    end

    private def record
      changelog, trunk, tag, date, url, *released = @argv
      return usage unless url

      text = read(trunk)
      return recorded_already(trunk, tag) if Changelog.new(text).released?(tag.delete_prefix("v"))

      listed = news(changelog, released).changes
      record = ReleaseRecord.new(tag:, date: Time.iso8601("#{date}T00:00:00Z"), listed:, repository_url: url)
      write(trunk, RecordedChangelog.new(text, record), tag)
    end

    private def write(trunk, recorded, tag)
      problem = recorded.problem
      return fail_with("#{trunk} #{problem}") if problem

      File.binwrite(trunk, recorded.to_s)
      succeed("recorded #{tag} in #{trunk}")
    end

    private def recorded_already(trunk, tag)
      succeed("#{trunk} has a heading for #{tag}, so trunk already records it", 3)
    end

    private def news(changelog, released)
      released_tag, released_changelog = released
      return News.new(read(changelog)) unless released_changelog

      News.new(
        read(changelog),
        released_version: released_tag.delete_prefix("v"),
        released_text: read(released_changelog)
      )
    end

    # A file's bytes as UTF-8, with the line endings it has, on every system.
    private def read(path)
      File.binread(path).force_encoding(Encoding::UTF_8)
    end

    private def succeed(message, status = 0)
      @out.puts("release-changelog.rb: #{message}")
      status
    end

    private def fail_with(message)
      @err.puts("release-changelog.rb: #{message}")
      1
    end

    private def usage
      @err.print(USAGE)
      2
    end
  end
end
