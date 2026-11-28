# frozen_string_literal: true

require_relative "news"
require_relative "version"

module ReleaseChangelog
  # What stops a tag's release before it publishes: a tag that is not newer
  # than every other release tag, a changelog that lists nothing new, or a
  # version that is not the one the changelog's entries call for.
  class Check
    # A check of +tag+, such as "v0.2.0", against the +other_tags+ that exist
    # and the +news+ of its changelog.
    def initialize(tag:, other_tags:, news:)
      @tag = tag
      @version = Version.parse(tag.delete_prefix("v"))
      @previous = other_tags.map { Version.parse(it.delete_prefix("v")) }
        .max
      @news = news
    end

    # Why the release must not publish, or nil.
    def problem
      not_newer || changelog_problem || nothing_new || not_called
    end

    private def not_newer
      "#{@tag} is not newer than v#{@previous}, the newest release tag" if @previous && @version <= @previous
    end

    private def changelog_problem
      problem = @news.problem
      "CHANGELOG.md #{problem}" if problem
    end

    private def nothing_new
      return unless @news.changes.empty?

      since = " since v#{@previous}" if @previous
      "CHANGELOG.md lists nothing new under ## [Unreleased]#{since}"
    end

    private def not_called
      called = @news.changes.version_after(@previous)
      "CHANGELOG.md calls for #{called}, not #{@version}" unless called == @version
    end
  end
end
