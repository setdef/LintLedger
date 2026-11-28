# frozen_string_literal: true

module Alibi
  class Report
    def initialize(name, verdict)
      @name = name
      @verdict = verdict
      freeze
    end

    def write(out)
      out.puts(summary)
      @verdict.each { |match| out.puts(Escaped.new(match.to_s).to_s) }
    end

    private def summary
      name = Escaped.new(@name)
      return "#{name}: passed: no matches #{scope}" if @verdict.passed?

      matches = @verdict.count
      "#{name}: failed: #{matches} #{(matches == 1) ? 'match' : 'matches'} #{scope}"
    end

    private def scope
      files = @verdict.files_checked
      "in #{files} #{(files == 1) ? 'file' : 'files'}"
    end
  end
end
