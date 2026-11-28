# frozen_string_literal: true

module Alibi
  class Match
    def initialize(path:, line:, text:)
      @path = path
      @line = line
      @text = text
      freeze
    end

    def to_s
      "#{@path}:#{@line}: #{@text}"
    end
  end
end
