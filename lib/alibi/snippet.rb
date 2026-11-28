# frozen_string_literal: true

module Alibi
  class Snippet
    def initialize(text)
      @lines = text.each_line(chomp: true).map(&:lstrip).freeze
      raise(Error, "an empty snippet: copy into it the lines that hold the alibi's match") if @lines.empty?

      freeze
    end

    def places_in(index)
      index.places(@lines).map { |first| first..(first + @lines.size - 1) }
    end

    def to_s
      %("#{@lines.first}")
    end
  end
end
