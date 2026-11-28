# frozen_string_literal: true

module ReleaseChangelog
  # A run of lines the changelog's reader skips: an HTML comment or a fenced
  # code block.
  class HiddenBlock
    COMMENT_OF_ONE_LINE = /\A\s*<!--.*-->/
    COMMENT_OPEN = /\A\s*<!--/
    COMMENT_CLOSE = /-->/
    # A fence of three or more backticks, with none in its info string, or
    # of three or more tildes.
    FENCE_OPEN = /\A\s*(?<marks>`{3,}(?=[^`]*\z)|~{3,})/

    private_constant(:COMMENT_OPEN, :COMMENT_CLOSE, :FENCE_OPEN)
    public_constant(:COMMENT_OF_ONE_LINE)

    # The block that +line+ opens, or nil when it opens none.
    def self.opened_by(line)
      return if COMMENT_OF_ONE_LINE.match?(line)
      return new(COMMENT_CLOSE) if COMMENT_OPEN.match?(line)

      marks = FENCE_OPEN.match(line)&.[](:marks)
      new(/\A\s*#{Regexp.escape(marks.chr)}{#{marks.size},}\s*\z/) if marks
    end

    # A block that ends at the first line the +closer+ pattern matches.
    def initialize(closer)
      @closer = closer
    end

    # Whether +line+ ends the block.
    def closed_by?(line)
      @closer.match?(line)
    end
  end
end
