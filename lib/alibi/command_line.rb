# frozen_string_literal: true

module Alibi
  class CommandLine
    PASSED = 0
    ERRORED = 2
    private_constant(:PASSED, :ERRORED)

    def initialize(out:, err:)
      @out = out
      @err = err
    end

    def run(arguments)
      @out.puts(Request.new(arguments).answers)
      PASSED
    rescue UsageError => e
      @err.puts("alibi: #{e.message}")
      ERRORED
    end
  end
end
