# frozen_string_literal: true

module Alibi
  class RollingHash
    BASE = 1_000_003
    MODULUS = 2_147_483_647
    # A prime modulus under 2**31 and a base under 2**20 keep every product
    # under 2**62, so the arithmetic never leaves Ruby's fixed-size integers.
    private_constant(:BASE, :MODULUS)

    def initialize(numbers)
      hash = 0
      # Each number counts one more than itself, so a run that starts with 0
      # doesn't hash as the shorter run after it.
      @prefixes = [0, *numbers.map { |number| hash = ((hash * BASE) + number + 1) % MODULUS }].freeze
      freeze
    end

    def of(start, size)
      (@prefixes[start + size] - (@prefixes[start] * BASE.pow(size, MODULUS))) % MODULUS
    end
  end
end
