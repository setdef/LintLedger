# frozen_string_literal: true

module Alibi
  class CheckedFile
    def initialize(index, matches)
      @index = index
      @matches = matches
      freeze
    end

    def places(snippet)
      snippet.places_in(@index)
    end

    def matches_within(lines)
      starting = @matches[first_starting_on(lines.begin)...first_starting_on(lines.end + 1)] #: Array[Match]
      starting.select { |match| match.within?(lines) }
    end

    private def first_starting_on(line)
      # The matches are in the order they start, so a search finds the first
      # one on or after a line in log time, however many the file has.
      @matches.bsearch_index { |match| !match.starts_before?(line) } || @matches.size
    end
  end
end
