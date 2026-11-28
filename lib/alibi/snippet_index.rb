# frozen_string_literal: true

module Alibi
  class SnippetIndex
    def initialize(text)
      @numbers = {} #: Hash[String, Integer]
      # Each distinct line, without its indent, gets a number, so comparing two
      # lines costs the same however long they are.
      @lines = text.each_line(chomp: true).map { |line| @numbers[line.lstrip] ||= @numbers.size }
      @hashes = RollingHash.new(@lines)
      @runs = {} #: Hash[Integer, Hash[Integer, Array[Integer]]]
      freeze
    end

    def places(lines)
      # A line the file doesn't have can't be part of a place in it.
      numbers = lines.map { |line| @numbers.fetch(line) { return [] } }
      numbers.empty? ? [] : starts(numbers).map(&:succ)
    end

    private def starts(numbers)
      size = numbers.size
      candidates = runs(size).fetch(RollingHash.new(numbers).of(0, size), [])
      # Runs of lines that differ can share a hash, so each one is compared in full.
      equal = candidates.lazy.select { |start| @lines[start, size] == numbers }
      equal.first(2)
    end

    private def runs(size)
      # Each size of snippet hashes every run of that many lines once, so a snippet
      # costs the snippet's length to find, not the file's.
      @runs[size] ||= (0..(@lines.size - size)).group_by { |start| @hashes.of(start, size) }
    end
  end
end
