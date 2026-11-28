# frozen_string_literal: true

module Alibi
  class Verdict
    include Enumerable

    def initialize(paths:, matches:, excused: [], failures: [])
      @paths = paths
      @matches = matches
      alibis = excused.tally
      @unexcused = matches.filter_map { |match| match.failure(alibis.fetch(match, 0)) }
      @failures = failures
      freeze
    end

    def each(&)
      [*@unexcused, *@failures].each(&)
    end

    def files_checked
      @paths.size
    end

    def matches_found
      @matches.size
    end

    def matches_failed
      @unexcused.size
    end

    def alibis_failed
      @failures.size
    end

    def passed?
      @unexcused.empty? && @failures.empty?
    end
  end
end
