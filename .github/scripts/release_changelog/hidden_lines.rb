# frozen_string_literal: true

require_relative "hidden_block"

module ReleaseChangelog
  # Tells, line by line, which lines of a changelog fall in a hidden block.
  class HiddenLines
    # A reader that is outside every block.
    def initialize
      @block = nil
    end

    # Whether +line+ is hidden. Call it with each line in order.
    def hide?(line)
      open = @block
      @block = open ? (open unless open.closed_by?(line)) : HiddenBlock.opened_by(line)
      [open, @block].any? || HiddenBlock::COMMENT_OF_ONE_LINE.match?(line)
    end
  end
end
