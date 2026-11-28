# frozen_string_literal: true

# RuboCop runs in a process of its own. Its configuration loader changes the working directory of the process that
# loads it, so RuboCop::RakeTask, which runs it inside rake, would send a check running beside it in another thread
# to the wrong folder.
desc "Run RuboCop, every cop on, over the Ruby, the RBS, and the Ruby in the Markdown"
task :rubocop do
  sh("bundle", "exec", "rubocop")
end

namespace :reuse do
  desc "Fail when a file has no copyright and license that REUSE can read, in the file or in REUSE.toml"
  task :lint do
    sh("reuse", "lint")
  end
end
