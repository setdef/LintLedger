# frozen_string_literal: true

module ReleaseChangelog
  # A Markdown list item, from the lines that start it and run on.
  class ListItem
    # A list item at the start of a line. An item further in belongs to the
    # item before it.
    START = /\A[-*+][ \t]+/
    # An item runs on through blank lines and indented lines, and through
    # text right after a line of its own, as a Markdown list item does. A
    # heading, or text at the start of a line after a blank line, ends it.
    ENDING = /\n(?:[ \t]*\n)+(?=\S)|\n(?=#)/

    private_constant(:ENDING)
    public_constant(:START)

    # The items among +lines+, each starting at a line that starts one.
    def self.split(lines)
      lines.slice_before(START).map { new(it) }
    end

    # An item from the +lines+ that start with it.
    def initialize(lines)
      @lines = lines
    end

    # Whether the first line starts a list item.
    def item?
      START.match?(@lines.first.to_s)
    end

    # The item's text, without its marker or trailing space.
    def text
      own.gsub(/[ \t]+$/, "").rstrip.sub(START, "")
    end

    # The number of lines the item has.
    def size
      own.count("\n") + 1
    end

    private def own
      @lines.join("\n").split(ENDING, 2).first.to_s
    end
  end
end
