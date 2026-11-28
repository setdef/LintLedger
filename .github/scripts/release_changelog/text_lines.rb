# frozen_string_literal: true

require_relative "changelog"

module ReleaseChangelog
  # A text split into lines, which joins back with the text's own line ending,
  # byte order mark, and final newline.
  class TextLines
    # The lines of +text+.
    def initialize(text)
      @text = text
    end

    # The text's lines, without the byte order mark or line endings.
    def to_a
      @text.delete_prefix(Changelog::BYTE_ORDER_MARK).lines(chomp: true)
    end

    # The +lines+ as a text in the original's form.
    def join(lines)
      ending = @text.include?("\r\n") ? "\r\n" : "\n"
      mark = @text.start_with?(Changelog::BYTE_ORDER_MARK) ? Changelog::BYTE_ORDER_MARK : ""
      "#{mark}#{lines.join(ending)}#{ending if @text.end_with?("\n")}"
    end
  end
end
