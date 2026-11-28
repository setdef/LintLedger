# frozen_string_literal: true

module Alibi
  class ProjectFile
    def initialize(path, content)
      text = content.dup.force_encoding(Encoding::UTF_8)
      raise(Error, "#{path} isn't UTF-8 text: list only text files in the glob") unless text.valid_encoding?

      @path = path
      # A Windows checkout gets the verdict a Linux one does.
      @text = text.gsub("\r\n", "\n").freeze
      freeze
    end

    def matches(regexp)
      found = @text.to_enum(:scan, regexp).filter_map { Regexp.last_match }
      found.map { |match_data| match_at(match_data.pre_match.length) }
    rescue Regexp::TimeoutError
      raise(Error, "the pattern ran for more than #{regexp.timeout} seconds over #{@path}")
    end

    private def match_at(offset)
      before = @text[0, offset].to_s
      start = before.rindex("\n")&.succ || 0
      Match.new(path: @path, line: before.count("\n") + 1, text: @text[start...line_end(offset)].to_s)
    end

    private def line_end(offset)
      @text.index("\n", offset) || @text.length
    end
  end
end
