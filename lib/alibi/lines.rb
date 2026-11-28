# frozen_string_literal: true

module Alibi
  class Lines
    def initialize(text)
      @text = text
      position = 0
      starts = text.each_line.map { |line| position.tap { position += line.bytesize } }
      # The starts are sorted, so a search finds a match's line in log time.
      @starts = [*starts, position]
      freeze
    end

    def number(offset)
      @starts.bsearch_index { |start| start > offset } || @starts.size
    end

    def at(offset)
      start = @starts.slice(number(offset) - 1) #: Integer
      @text.byteslice(start, (@text.byteindex("\n", offset) || @text.bytesize) - start).to_s
    end
  end
end
