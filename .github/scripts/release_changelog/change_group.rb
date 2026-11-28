# frozen_string_literal: true

require_relative "entry"
require_relative "list_item"

module ReleaseChangelog
  # The lines under one ### heading of the Unreleased section, or the lines
  # before the first heading.
  class ChangeGroup
    HEADING = /\A### +(?<name>.*?)\s*\z/

    public_constant(:HEADING)

    # A group of the +lines+, the first of which is its heading.
    def initialize(lines)
      @name = HEADING.match(lines.first.to_s)&.[](:name)&.to_sym
      @items = ListItem.split(lines).select(&:item?)
    end

    # What is wrong with the group, as a phrase for a changelog, or nil.
    def problem
      return heading_problem if @name

      "lists an entry under ## [Unreleased] before its first ### heading" unless @items.empty?
    end

    # The group's entries, none when its heading is not one of Keep a Changelog's.
    def entries
      heading = @name
      return [] unless heading && Entry::HEADINGS.key?(heading)

      @items.map { Entry.new(heading, it.text) }
    end

    private def heading_problem
      return if Entry::HEADINGS.key?(@name)

      known = Entry::HEADINGS.keys.map { "### #{it}" }
      "has ### #{@name} under ## [Unreleased], where the release reads only #{known.join(', ')}"
    end
  end
end
