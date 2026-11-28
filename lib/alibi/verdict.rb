# frozen_string_literal: true

module Alibi
  class Verdict
    include Enumerable

    def initialize(paths:, matches:)
      @paths = paths
      @matches = matches
      freeze
    end

    def each(&)
      @matches.each(&)
    end

    def files_checked
      @paths.size
    end

    def passed?
      @matches.empty?
    end
  end
end
