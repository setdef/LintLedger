# frozen_string_literal: true

module Alibi
  class Pattern
    TIMEOUT = 2.0
    private_constant(:TIMEOUT)

    def initialize(source, timeout: TIMEOUT)
      @regexp = compile(source, timeout)
      refuse_empty_matches
      refuse_superlinear
    end

    def matches(file)
      file.matches(@regexp)
    end

    def to_s
      @regexp.inspect
    end

    private def refuse_empty_matches
      return unless @regexp.match?("")

      raise(
        Error,
        "the pattern #{self} can match empty text, so it would match at every position of every file: " \
          "write it so that every match has at least one character"
      )
    end

    private def refuse_superlinear
      return if Regexp.linear_time?(@regexp)

      raise(
        Error,
        "Ruby can't match the pattern #{self} in linear time, so it could hang Alibi: remove its back-references, " \
          "captures inside lookarounds, nested quantifiers, absence operators, and conditionals"
      )
    end

    private def compile(source, timeout)
      Regexp.new(source, timeout:)
    rescue RegexpError => e
      raise(Error, "the pattern isn't a valid Ruby regexp: #{e.message}")
    end
  end
end
