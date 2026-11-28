# frozen_string_literal: true

require_relative "hidden_lines"

module ReleaseChangelog
  # The lines of a changelog's section that a reader sees: all but the lines
  # of an HTML comment or a fenced code block.
  class VisibleLines
    include Enumerable

    # The visible lines among +lines+.
    def initialize(lines)
      @lines = lines
    end

    # Yields each visible line.
    def each(&)
      indices.each { yield(@lines[it]) }
    end

    # The positions of the visible lines among all the lines.
    def indices
      hidden = HiddenLines.new
      @lines.each_index.reject { hidden.hide?(@lines[it]) }
    end
  end
end
