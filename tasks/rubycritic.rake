# frozen_string_literal: true

require_relative("critic_faults")

# The floor for the RubyCritic score. It may rise, never fall.
RUBYCRITIC_MINIMUM_SCORE = 95
RUBYCRITIC_REPORT_DIR = "tmp/rubycritic"

# RubyCritic runs in a shell so that it can't exit the rake process, then the task reads its JSON report: the score is
# at least the floor, every file is rated A, and no smell from reek or flay is left.
desc "Run RubyCritic: a score of at least #{RUBYCRITIC_MINIMUM_SCORE}, every file rated A, no smells"
task :rubycritic do
  report = File.join(RUBYCRITIC_REPORT_DIR, "report.json")
  FileUtils.rm_f(report)
  command = %w[bundle exec rubycritic --no-browser --format json --path] << RUBYCRITIC_REPORT_DIR
  system(*command, "lib", "sig")
  abort("RubyCritic wrote no report.") unless File.exist?(report)

  lines = CriticFaults.in_report(File.read(report), floor: RUBYCRITIC_MINIMUM_SCORE).map { |fault| "  #{fault}" }
  abort("RubyCritic faults:\n#{lines.join("\n")}") unless lines.empty?
end
