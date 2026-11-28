# frozen_string_literal: true

module Alibi
  class Count
    def initialize(number, one, many)
      @number = number
      @one = one
      @many = many
      freeze
    end

    def none?
      @number.zero?
    end

    def to_s
      "#{@number} #{(@number == 1) ? @one : @many}"
    end
  end
end
