# frozen_string_literal: true

# Steep loads every target's signatures into every other target, so a library
# that any signature names has to load in every target. A target that lacks one
# fails to build its types, and Steep then checks none of its files and reports
# no error. A library goes in this list, once, for all of them.
libraries = %w[json minitest open3 optparse stringio].freeze

target :lib do
  signature "sig"
  check "lib"
  check "exe/alibi"

  configure_code_diagnostics(Steep::Diagnostic::Ruby.all_error)

  library(*libraries)
end

target :tasks do
  signature "tasks/sig"
  check "tasks"

  configure_code_diagnostics(Steep::Diagnostic::Ruby.all_error)

  library(*libraries)
  library "ripper"
end
