# frozen_string_literal: true

require_relative "entry"
require_relative "version"

module ReleaseChangelog
  # The entries of a changelog's Unreleased section.
  class Changes
    include Enumerable

    # From the least a change can raise a version to the most.
    ORDER = %i[patch minor major].freeze

    private_constant(:ORDER)

    # Changes made of the +entries+.
    def initialize(entries)
      @entries = entries
    end

    # Yields each entry.
    def each(&)
      @entries.each(&)
    end

    # The entries left after taking away, one for one, the +earlier+ ones with
    # the same text.
    def since(earlier)
      listed = earlier.map(&:text).tally
      taken = Hash.new(0)
      Changes.new(@entries.reject { |entry| entry.text.then { listed.fetch(it, 0) >= (taken[it] += 1) } })
    end

    # Whether there is no entry.
    def empty?
      @entries.empty?
    end

    # The version a release of these entries follows +previous+ with, or the
    # first version when +previous+ is nil.
    def version_after(previous)
      previous ? previous.after(change) : Version.initial
    end

    # The entries as release notes, each under its heading.
    def notes
      sections = @entries.group_by(&:heading).map { |heading, entries| "### #{heading}\n\n#{entries.join("\n")}\n" }
      sections.join("\n")
    end

    private def change
      ORDER.rfind { |level| @entries.any? { it.change == level } } || :patch
    end
  end
end
