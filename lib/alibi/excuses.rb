# frozen_string_literal: true

module Alibi
  class Excuses
    def initialize
      @excused = [] #: Array[Match]
      @failures = [] #: Array[String]
    end

    def excused(match)
      @excused << match
      self
    end

    def failed(failure)
      @failures << failure
      self
    end

    def verdict(paths:, matches:)
      Verdict.new(paths:, matches:, excused: @excused, failures: @failures)
    end
  end
end
