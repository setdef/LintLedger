# frozen_string_literal: true

require_relative "change_group"
require_relative "list_item"
require_relative "section_part"

module ReleaseChangelog
  # The lines of one ### heading of the Unreleased section, by position.
  class SectionGroup
    # The group of the visible line positions +places+, which ends before
    # position +finish+.
    def initialize(lines, places, finish)
      @lines = lines
      @places = places
      @finish = finish
    end

    # The ranges of lines to drop, to take away the entries that +listed+
    # holds, and the heading too when none is left.
    def spans_without(listed)
      spans = parts.filter_map { |part| part.span if listed.take?(part.item) }
      emptied?(spans) ? [(@places.first)...@finish] : spans
    end

    private def parts
      split = @places.slice_before { ListItem::START.match?(@lines[it]) }
        .to_a
      split.each_with_index.map { |places, at| SectionPart.new(@lines, places, split.dig(at + 1, 0) || @finish) }
    end

    private def emptied?(spans)
      heading = @places.first
      return false if spans.empty? || !ChangeGroup::HEADING.match?(@lines[heading])

      ((heading + 1)...@finish).none? { |place| spans.none? { it.cover?(place) } && @lines[place].match?(/\S/) }
    end
  end
end
