# frozen_string_literal: true

module Alibi
  class AlibiFile
    class Alibi
      STALE = "matches nothing: remove it, or bring its path and snippet up to date"
      private_constant(:STALE)

      def initialize(path:, snippet:, reason:, occurrence: nil)
        @path = path
        @snippet = snippet
        @reason = reason
        @occurrence = occurrence
        freeze
        return unless occurrence&.<(1)

        raise(Error, "#{self} has occurrence #{occurrence}: count the matches in its snippet from 1")
      end

      def claim(files, excuses)
        file = files.at(@path)
        lines, again = file.places(@snippet)
        return excuses.failed("#{@path}: #{self} #{STALE}") unless lines

        # An alibi excuses one place, so it never picks one of several.
        again ? excuses.failed(ambiguous(lines, again)) : hold(file, lines, excuses)
      end

      def to_s
        "the alibi for #{@snippet}"
      end

      private def hold(file, lines, excuses)
        SnippetMatches.new(file.matches_within(lines), @occurrence).claim(excuses) { |why| none(lines, why) }
      end

      private def ambiguous(lines, again)
        why = "its snippet occurs here and again on line #{again.begin}: copy lines from around its match into the " \
          "snippet until it occurs once"
        none(lines, why)
      end

      private def none(lines, why)
        "#{@path}:#{lines.begin}: #{self} excuses no match, since #{why}"
      end
    end
  end
end
