# frozen_string_literal: true

module Alibi
  class Glob
    FLAGS = File::FNM_PATHNAME | File::FNM_EXTGLOB | File::FNM_DOTMATCH
    ABSOLUTE = %r{\A(?:[/\\~]|[A-Za-z]:)}
    SEPARATOR = %r{[/\\]}
    private_constant(:FLAGS, :ABSOLUTE, :SEPARATOR)

    def initialize(text)
      @text = text
      freeze
      fault = outside_root
      raise(Error, "the glob #{text.inspect} #{fault}") if fault
    end

    def select(paths)
      paths.select { |path| File.fnmatch?(@text, path, FLAGS) }
    end

    def to_s
      @text
    end

    private def outside_root
      # An alibi file gets the same verdict on every system, so Alibi refuses
      # a root, a share, a drive, or a home folder on all of them.
      return "is absolute: write it relative to the project root" if ABSOLUTE.match?(@text)

      "has a \"..\" segment: write it inside the project root" if @text.split(SEPARATOR).include?("..")
    end
  end
end
