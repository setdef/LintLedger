# frozen_string_literal: true

module Alibi
  class CommandLine
    PASSED = 0
    FAILED = 1
    ERRORED = 2
    private_constant(:PASSED, :FAILED, :ERRORED)

    def initialize(out:, err:, folder: Dir.pwd, projects: Project)
      @out = out
      @err = err
      @folder = folder
      @projects = projects
    end

    def run(arguments)
      request = Request.new(arguments)
      answer(request.answers) || check_each(request.alibi_files { AlibiFolder.new(@folder).names })
    rescue UsageError, Error => e
      fail_with(e.message)
    end

    private def answer(lines)
      return if lines.empty?

      @out.puts(lines)
      PASSED
    end

    private def check_each(names)
      statuses = names.map { |name| check(name) }
      # The highest status wins, so an error in any alibi file outweighs a failure.
      statuses.max
    end

    private def check(name)
      report_on(name).passed? ? PASSED : FAILED
    rescue Error, SystemCallError => e
      fail_with("#{name}: #{e.message}")
    end

    private def report_on(name)
      path = File.expand_path(name, @folder)
      verdict = AlibiFile.parse(AlibiFileReader.new(path).bytes).check(@projects.containing(File.dirname(path)))
      Report.new(name, verdict).write(@out)
      verdict
    end

    private def fail_with(message)
      @err.puts("alibi: #{Escaped.new(message)}")
      ERRORED
    end
  end
end
