# frozen_string_literal: true

module Alibi
  class AlibiFolder
    PATH = ".config/alibi"
    private_constant(:PATH)

    def initialize(folder)
      @folder = folder
      freeze
    end

    def names
      names = Dir.glob("*.kdl", base: File.join(@folder, PATH)).sort
      raise(Error, "no alibi files in #{PATH}/: add one there, or name one on the command line") if names.empty?

      names.map { |name| "#{PATH}/#{name}" }
    end
  end
end
