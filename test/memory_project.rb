# frozen_string_literal: true

# Stands in for Alibi::Project, and for the class itself, in memory: a project
# whose files are the given pairs of path and bytes, whatever folder holds the
# alibi file.
class MemoryProject
  attr_reader(:folders)

  def initialize(*files)
    @files = files.to_h
    @folders = []
  end

  def containing(folder)
    @folders << folder
    self
  end

  def paths
    @files.keys
  end

  def file(path)
    Alibi::ProjectFile.new(path, @files[path])
  end
end
