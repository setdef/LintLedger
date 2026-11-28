# frozen_string_literal: true

# Makes a Ruby warning about the project's own code raise, so that the run fails on it. Ruby starts each warning it gives
# with the file and line, such as for an unused variable, and that file tells the project's code from a gem's. Ruby gives
# every warning to Warning.warn, so a hook there sees the parser's warnings and those of code that runs, in this process.
module ProjectWarnings
  ROOT = File.expand_path("..", __dir__)
  # The folders that RuboCop leaves out, where no code of the project's is.
  LEFT_OUT = [File.join(ROOT, "coverage", ""), File.join(ROOT, "tmp", ""), File.join(ROOT, "vendor", "")].freeze
  FILE_AND_LINE = /\A(?<path>.+?):\d+: warning: /
  private_constant(:ROOT, :LEFT_OUT, :FILE_AND_LINE)

  # The warning that Ruby gave about a file of the project, as the message it gave.
  class Fault < StandardError; end

  # Whether Ruby gave the warning about a file in this project, and not a gem or a folder RuboCop leaves out.
  def self.own?(message)
    path = FILE_AND_LINE.match(message)&.[](:path)
    return false unless path

    absolute = File.expand_path(path)
    absolute.start_with?(File.join(ROOT, "")) && LEFT_OUT.none? { |folder| absolute.start_with?(folder) }
  end

  # Raises Fault for a warning about the project's own code, and gives every other warning to Ruby as usual.
  module Hook
    def warn(message, ...)
      raise(Fault, message) if ProjectWarnings.own?(message)

      super
    end
  end
end

Warning.extend(ProjectWarnings::Hook)
