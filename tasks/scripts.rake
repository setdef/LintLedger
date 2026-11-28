# frozen_string_literal: true

require_relative("shell_scripts")

desc "Run actionlint over every workflow in .github/workflows"
task :actionlint do
  workflows = Dir.glob(".github/workflows/*.{yml,yaml}")
  next puts("No workflow to lint.") if workflows.empty?

  sh("actionlint", *workflows)
end

desc "Run ShellCheck over every shell script in the project"
task :shellcheck do
  # The files that git tracks and the ones it would track, so a script that no commit holds yet is checked too.
  listing = IO.popen(%w[git ls-files --cached --others --exclude-standard -z], &:read)
  scripts = ShellScripts.among(listing.split("\0"))
  next puts("No shell script to check.") if scripts.empty?

  sh("shellcheck", *scripts)
end
