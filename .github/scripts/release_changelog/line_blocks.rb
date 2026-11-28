# frozen_string_literal: true

module ReleaseChangelog
  # Blocks of lines, joined with one blank line between them.
  module LineBlocks
    # The +blocks+ as one list of lines, each block without its blank lines at
    # the ends, and none for a block that is only blank.
    def self.join(blocks)
      kept = blocks.map { trim(it) }
      kept.reject!(&:empty?)
      kept.reduce { |acc, elem| [*acc, "", *elem] } || []
    end

    # The +lines+ without the blank ones at either end.
    def self.trim(lines)
      text = -> (line) { !blank?(line) }
      first = lines.index(&text)
      first ? lines[first..(lines.rindex(&text))].to_a : []
    end

    # Whether +line+ is empty or only space.
    def self.blank?(line)
      line.strip.empty?
    end
  end
end
