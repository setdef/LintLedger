# frozen_string_literal: true

module Alibi
  class SnippetMatches
    def initialize(matches, occurrence)
      @matches = matches
      @occurrence = occurrence
      freeze
    end

    def claim(excuses)
      match = excused
      match ? excuses.excused(match) : excuses.failed(yield(problem))
    end

    private def excused
      occurrence = @occurrence
      occurrence ? @matches[occurrence - 1] : (@matches.first if @matches.one?)
    end

    private def problem
      count = @matches.size
      return "its snippet holds none: remove it, or bring its snippet up to date" if count.zero?
      return "its occurrence is #{@occurrence} and its snippet holds #{count}: lower its occurrence" if @occurrence

      "its snippet holds #{count}: cut the snippet down to the lines around one, or give the alibi an occurrence " \
        "when they share a line"
    end
  end
end
