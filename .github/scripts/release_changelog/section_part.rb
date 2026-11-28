# frozen_string_literal: true

require_relative "list_item"

module ReleaseChangelog
  # The lines from one list item to the next, by position.
  class SectionPart
    # The part of the visible line positions +places+, which ends before
    # position +finish+.
    def initialize(lines, places, finish)
      @lines = lines
      @places = places
      @finish = finish
    end

    # The list item the part starts with.
    def item
      ListItem.new(@places.map { @lines[it] })
    end

    # The range of lines the item takes up. An indented line after the item's
    # lines, such as a line of a code block the reader skips, is still part of
    # the item in Markdown.
    def span
      after = @places[item.size - 1] + 1
      (@places.first)...((after...@finish).find { @lines[it].match?(/\A\S/) } || @finish)
    end
  end
end
