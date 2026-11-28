# frozen_string_literal: true

module Alibi
  class AlibiFile
    def self.parse(source)
      Parser.new(source).alibi_file
    end

    def initialize(glob:, pattern:)
      @glob = glob
      @pattern = pattern
      freeze
    end

    def check(project)
      paths = @glob.select(project.paths)
      Verdict.new(paths:, matches: paths.flat_map { |path| @pattern.matches(project.file(path)) })
    end
  end
end
