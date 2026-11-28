# frozen_string_literal: true

module Alibi
  class Escaped
    CONTROL = /[\x00-\x08\x0A-\x1F\x7F\u0080-\u009F\u2028\u2029\u202A-\u202E\u2066-\u2069]/
    private_constant(:CONTROL)

    def initialize(text)
      @text = text
      freeze
    end

    def to_s
      printable = @text.scrub { |bytes| escape(bytes) }
      printable.gsub(CONTROL) { |character| escape(character) }
    end

    private def escape(text)
      text.each_byte.sum("") { |byte| format("\\x%02X", byte) }
    end
  end
end
