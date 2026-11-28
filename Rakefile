# frozen_string_literal: true

# Import the tasks of each gate.
Dir.glob("tasks/**/*.rake").each { |path| import(path) }

desc "Run every gate, as CI does"
task default: %w[bundle:frozen test]
