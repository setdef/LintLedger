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
      paths = files_in(project)
      Verdict.new(paths:, matches: paths.flat_map { |path| @pattern.matches(project.file(path)) })
    end

    private def files_in(project)
      paths = @glob.select(project.paths)
      return paths unless paths.empty?

      # An alibi file that checks nothing most likely has a mistyped glob.
      raise(
        Error,
        "the glob #{@glob.to_s.inspect} matches no file in the project: check it for a typo, or delete the alibi file"
      )
    end
  end
end
