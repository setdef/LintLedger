# frozen_string_literal: true

# Import the tasks of each gate.
Dir.glob("tasks/**/*.rake").each { |path| import(path) }

# Default runs gates only, never fixers. Its checks are independent, so they
# run at once, each on the cores it needs, and the longest one sets the time.
desc "Run every check of the gate at once"
multitask default: %w[
  bundle:frozen test rubocop rubycritic steep reuse:lint rdoc:coverage docs:placement actionlint shellcheck alibi
]
