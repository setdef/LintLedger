# frozen_string_literal: true

module Alibi
  class ProjectFile
    def initialize(path, content)
      text = content.dup.force_encoding(Encoding::UTF_8)
      raise(Error, "#{path} isn't UTF-8 text: list only text files in the glob") unless text.valid_encoding?

      @path = path
      # A Windows checkout gets the verdict a Linux one does.
      @text = text.gsub("\r\n", "\n").freeze
      @lines = Lines.new(@text)
      freeze
    end

    def matches(regexp)
      found = @text.to_enum(:scan, regexp).filter_map { Regexp.last_match }
      found.map { |match_data| match_at(match_data) }
    rescue Regexp::TimeoutError
      raise(Error, "the pattern ran for more than #{regexp.timeout} seconds over #{@path}")
    end

    def snippet_index
      SnippetIndex.new(@text)
    end

    private def match_at(match_data)
      offset, finish = match_data.byteoffset(0) #: [Integer, Integer]
      Match.new(
        path: @path, line: @lines.number(offset), text: @lines.at(offset), last_line: @lines.number(finish - 1)
      )
    end
  end
end
