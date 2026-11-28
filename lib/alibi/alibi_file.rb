# frozen_string_literal: true

module Alibi
  class AlibiFile
    def self.parse(source)
      Parser.new(source).alibi_file
    end

    def initialize(glob:, pattern:, alibis: [])
      @glob = glob
      @pattern = pattern
      @alibis = alibis
      freeze
    end

    def check(project)
      files = files_in(project).to_h { |path| [path, project.file(path)] }
      hear(files, files.transform_values { |file| @pattern.matches(file) })
    end

    private def hear(files, matches)
      checked = CheckedFiles.new(files, matches)
      excuses = Excuses.new
      @alibis.each { |alibi| alibi.claim(checked, excuses) }
      excuses.verdict(paths: files.keys, matches: matches.values.flat_map(&:itself))
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
