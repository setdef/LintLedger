# frozen_string_literal: true

module Alibi
  class CheckedFiles
    def initialize(files, matches)
      @files = files
      @matches = matches
      @checked = {} #: Hash[String, CheckedFile]
    end

    def at(path)
      # A file's index is built once, and only when an alibi is for the file. A
      # path the glob doesn't match is an empty file, where nothing occurs.
      @checked[path] ||= begin
        file = @files.fetch(path) { ProjectFile.new(path, "") }
        CheckedFile.new(file.snippet_index, @matches.fetch(path, []))
      end
    end
  end
end
