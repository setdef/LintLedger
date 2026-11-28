# frozen_string_literal: true

require "optparse"

module Alibi
  class CommandLine
    PASSED = 0
    ERRORED = 2
    USAGE = "Usage: alibi [--version] [--help]"
    private_constant(:PASSED, :ERRORED, :USAGE)

    def initialize(out:, err:)
      @out = out
      @err = err
    end

    def run(arguments)
      answers = []
      parser = OptionParser.new
      parser.on("--version") { answers << VERSION }
      parser.on("--help") { answers << USAGE }
      return fail_with("expected --version or --help") unless parser.parse(arguments).empty? && !answers.empty?

      @out.puts(answers)
      PASSED
    rescue OptionParser::ParseError => error
      fail_with(error.message)
    end

    private

    def fail_with(message)
      @err.puts("alibi: #{message}")
      ERRORED
    end
  end
end
