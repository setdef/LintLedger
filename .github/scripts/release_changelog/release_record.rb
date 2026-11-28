# frozen_string_literal: true

require_relative "listed_texts"

module ReleaseChangelog
  # What a release adds to the changelog: its dated heading, the entries it
  # listed, and its link definitions.
  class ReleaseRecord
    # The record of the release at +tag+, such as "v0.4.0", made on +date+
    # (a Time) of the +listed+ entries, in the repository at +repository_url+.
    def initialize(tag:, date:, listed:, repository_url:)
      @tag = tag
      @date = date
      @listed = listed
      @url = repository_url
    end

    # The tag, such as "v0.4.0".
    def tag
      @tag.to_s
    end

    # The version, such as "0.4.0".
    def version
      @tag.delete_prefix("v")
    end

    # The dated heading and the entries under it, as lines.
    def section
      ["## [#{version}] - #{@date.utc.strftime('%F')}", "", *@listed.notes.lines(chomp: true)]
    end

    # The texts of the entries the release listed, to take away from Unreleased.
    def listed_texts
      ListedTexts.new(@listed)
    end

    # The definition of the Unreleased link with +label+, which compares from
    # the release's tag.
    def unreleased_link(label)
      "[#{label}]: #{@url}/compare/#{@tag}...HEAD"
    end

    # The definition of the link to the release's page.
    def release_link
      "[#{version}]: #{@url}/releases/tag/#{@tag}"
    end
  end
end
