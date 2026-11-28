# frozen_string_literal: true

module Alibi
  class Report
    def initialize(name, verdict)
      @name = name
      @verdict = verdict
      freeze
    end

    def write(out)
      out.puts(summary)
      @verdict.each { |failure| out.puts(Escaped.new(failure.to_s).to_s) }
    end

    private def summary
      name = Escaped.new(@name)
      @verdict.passed? ? "#{name}: passed: #{excused}" : "#{name}: failed: #{failed} #{scope}"
    end

    private def excused
      found = Count.new(@verdict.matches_found, "match", "matches")
      found.none? ? "no matches #{scope}" : "#{found} #{scope}, each with its alibi"
    end

    private def failed
      matches = Count.new(@verdict.matches_failed, "match", "matches")
      [matches, Count.new(@verdict.alibis_failed, "alibi", "alibis")].reject(&:none?).join(" and ")
    end

    private def scope
      "in #{Count.new(@verdict.files_checked, 'file', 'files')}"
    end
  end
end
