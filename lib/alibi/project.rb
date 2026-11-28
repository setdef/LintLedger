# frozen_string_literal: true

require "open3"

module Alibi
  class Project
    LIST = %w[ls-files -z --cached --others --exclude-standard].freeze
    private_constant(:LIST)

    def self.containing(folder)
      root, _errors, status = Open3.capture3("git", "-C", folder, "rev-parse", "--show-toplevel")
      unless status.success?
        raise(Error, "#{folder} isn't inside a git working tree: keep the alibi file in the project it checks")
      end

      new(root.chomp)
    end

    def initialize(root)
      @root = root
      freeze
    end

    def paths
      # Untracked files count, so a new file is checked before anyone stages
      # it, and ignored ones don't, so build output is never read.
      listing, errors, status = Open3.capture3("git", "-C", @root, *LIST)
      # A listing that failed is no listing: a check that read no files would pass.
      raise(Error, "git couldn't list the files of #{@root}: #{errors.chomp}") unless status.success?

      listing.split("\0").uniq.select { |path| regular?(path) }
    end

    def file(path)
      ProjectFile.new(path, File.binread(File.join(@root, path)))
    end

    private def regular?(path)
      # Git lists a tracked file that was deleted, and a symlink, which Alibi
      # never follows out of the project.
      File.lstat(File.join(@root, path)).file?
    rescue Errno::ENOENT
      false
    end
  end
end
