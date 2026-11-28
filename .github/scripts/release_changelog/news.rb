# frozen_string_literal: true

require_relative "changelog"
require_relative "changes"

module ReleaseChangelog
  # The entries a tag's release lists: those under Unreleased in the changelog
  # at the tagged commit, less the ones the newest published release before it
  # listed, when the changelog doesn't record that release yet.
  class News
    # The news of the changelog in +text+. +released_version+ and +released_text+
    # are the newest published release before the tag and its changelog.
    def initialize(text, released_version: nil, released_text: nil)
      @changelog = Changelog.new(text)
      @released_version = released_version
      @released_text = released_text
    end

    # What is wrong with the changelog, as a phrase that follows its name, or nil.
    def problem
      @changelog.problem
    end

    # The entries the release lists.
    def changes
      @changes ||= @changelog.changes.since(listed)
    end

    private def listed
      return Changes.new([]) unless @released_text && !@changelog.released?(@released_version)

      Changelog.new(@released_text).changes
    end
  end
end
