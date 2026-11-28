# frozen_string_literal: true

module Alibi
  class Report
    CONTROL = /[\x00-\x08\x0A-\x1F\x7F]/
    ESCAPES = [*0x00..0x08, *0x0A..0x1F, 0x7F].to_h { |code| [code.chr, format("\\x%02X", code)] }
    ESCAPES.freeze
    private_constant(:CONTROL, :ESCAPES)

    def initialize(name, verdict)
      @name = name
      @verdict = verdict
      freeze
    end

    def write(out)
      out.puts(summary)
      # A file Alibi reads must not move the cursor, clear the screen, or set
      # the title of the terminal, so every control character but a tab shows
      # as an escape.
      @verdict.each { |match| out.puts(match.to_s.gsub(CONTROL, ESCAPES)) }
    end

    private def summary
      return "#{@name}: passed: no matches #{scope}" if @verdict.passed?

      matches = @verdict.count
      "#{@name}: failed: #{matches} #{(matches == 1) ? 'match' : 'matches'} #{scope}"
    end

    private def scope
      files = @verdict.files_checked
      "in #{files} #{(files == 1) ? 'file' : 'files'}"
    end
  end
end
