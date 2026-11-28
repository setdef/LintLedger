# frozen_string_literal: true

require "optparse"

module Alibi
  class Request
    USAGE = "Usage: alibi [FILE.kdl ...] [--version] [--help]"
    private_constant(:USAGE)

    def initialize(arguments)
      @options = {} #: Hash[Symbol, bool]
      parser = OptionParser.new do |options|
        # An abbreviation such as --vers would shadow the options a later version adds.
        options.require_exact = true
        options.on("--version")
        options.on("--help")
      end
      @leftovers = parser.parse(arguments, into: @options)
    rescue OptionParser::ParseError => e
      raise(UsageError, e.message)
    end

    def answers
      raise(UsageError, "--version and --help take no alibi file") unless @leftovers.empty? || @options.empty?

      [(VERSION if @options[:version]), (USAGE if @options[:help])].compact
    end

    def alibi_files
      @leftovers.empty? ? yield : @leftovers
    end
  end
end
