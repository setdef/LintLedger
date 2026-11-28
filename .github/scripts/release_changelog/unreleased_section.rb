# frozen_string_literal: true

require_relative "change_group"
require_relative "section_group"

module ReleaseChangelog
  # The lines under a changelog's Unreleased heading.
  class UnreleasedSection
    # The section at +range+ of +lines+, whose visible lines are at the
    # positions +visible+.
    def initialize(lines, visible, range)
      @lines = lines
      @visible = visible
      @range = range
    end

    # The section's lines without the entries of +listed+, taken one for one.
    def without(listed)
      gone = groups.flat_map { it.spans_without(listed) }
      spaced(@range.reject { |place| gone.any? { it.cover?(place) } })
    end

    private def groups
      split = @visible.slice_before { heading?(it) }
        .to_a
      split.each_with_index.map { |places, at| SectionGroup.new(@lines, places, split.dig(at + 1, 0) || @range.end) }
    end

    # A heading after an entry that was taken away gets the blank line that
    # the entry's lines ended with.
    private def spaced(places)
      places.zip([nil, *places]).flat_map { |place, before| [*gap(before, place), @lines[place]] }
    end

    private def gap(before, place)
      (before && heading?(place) && @lines[before].match?(/\S/)) ? [""] : []
    end

    private def heading?(place)
      @visible.include?(place) && ChangeGroup::HEADING.match?(@lines[place])
    end
  end
end
