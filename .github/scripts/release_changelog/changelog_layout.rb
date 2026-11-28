# frozen_string_literal: true

require_relative "changelog"
require_relative "changelog_footer"
require_relative "visible_lines"

module ReleaseChangelog
  # Where the parts of a changelog's lines are: the head, the Unreleased
  # section, the older releases, and the footer of link definitions.
  class ChangelogLayout
    # The layout of +lines+, whose Unreleased heading is at index +start+.
    def initialize(lines, start)
      @lines = lines
      @first = start + 1
    end

    # The range of lines up to and with the Unreleased heading.
    def head
      0...@first
    end

    # The range of lines under the Unreleased heading.
    def unreleased
      @first...stop
    end

    # The positions of the visible lines of the Unreleased section.
    def visible
      visible_after.select { it < stop }
    end

    # The range of lines of the releases before Unreleased.
    def older
      stop...footer
    end

    # The position where the footer's link definitions start.
    def footer
      place = @lines.size
      place -= 1 while place > @first && ChangelogFooter.line?(@lines[place - 1])
      place
    end

    private def stop
      [visible_after.find { Changelog::SECTION_END.match?(@lines[it]) }, footer].compact.min
    end

    private def visible_after
      VisibleLines.new(@lines.drop(@first)).indices.map { it + @first }
    end
  end
end
