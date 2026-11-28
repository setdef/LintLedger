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
  end
end
