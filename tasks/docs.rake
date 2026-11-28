# frozen_string_literal: true

require "rdoc/task"
require_relative("ruby_doc_comments")

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = ENV.fetch("RDOC_OUTPUT", "tmp/rdoc")
  # The documentation lives in sig/**/*.rbs, which RDoc reads only as input.
  rdoc.rdoc_files.include("lib/**/*.rb", "sig/**/*.rbs")
end

Rake::Task["rdoc:coverage"].clear_comments
Rake::Task["rdoc:coverage"].comment = "Fail when a public class, module, constant, or method has no RDoc"

namespace :docs do
  desc "Fail when a comment in lib sits above a definition, where RDoc would take it as documentation"
  task :placement do
    faults = Dir.glob("lib/**/*.rb").flat_map { |path| RubyDocComments.in_source(File.read(path), path) }
    next puts("No comment in lib sits above a definition.") if faults.empty?

    abort(faults.join("\n"))
  end
end
