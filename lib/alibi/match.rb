# frozen_string_literal: true

module Alibi
  class Match
    def initialize(path:, line:, text:, last_line: line)
      @path = path
      @line = line
      @text = text
      @last_line = last_line
      freeze
    end

    def starts_before?(line)
      @line < line
    end

    def within?(lines)
      lines.cover?(@line) && lines.cover?(@last_line)
    end

    def to_s
      "#{@path}:#{@line}: #{@text}"
    end

    def failure(alibis)
      return self if alibis.zero?

      # One alibi for each match, so each reason is tied to one place.
      "#{@path}:#{@line}: #{alibis} alibis excuse this match: keep one: #{@text}" if alibis > 1
    end
  end
end
