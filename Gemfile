# frozen_string_literal: true

source "https://rubygems.org"

# Specify the gem's dependencies in alibi.gemspec.
gemspec

# Runs the tasks, among them the release build (rake build).
gem "rake", "~> 13.0"

# The gems that only the checks use. The release build leaves them out of the app.
group :check do
  # Runs the tests.
  gem "minitest", "~> 6.0"
  # Measures test coverage, and fails below 100% of lines and branches.
  gem "simplecov", "~> 1.3"

  # Lints the code and the Ruby in Markdown, with the plugins below.
  gem "rubocop", "~> 1.21"
  # Lints the Ruby code blocks in Markdown files.
  gem "rubocop-md", "~> 3.0"
  # Lints the tests.
  gem "rubocop-minitest", "~> 0.41"
  # Lints the RBS files.
  gem "rubocop-on-rbs", "~> 2.2"
  # Lints the gemspec for packaging mistakes.
  gem "rubocop-packaging", "~> 0.6"
  # Flags code that can run faster.
  gem "rubocop-performance", "~> 1.27"
  # Lints the Rake tasks.
  gem "rubocop-rake", "~> 0.7"
  # Flags code that is unsafe across threads.
  gem "rubocop-thread_safety", "~> 0.8"

  # Scores each file's complexity, in RubyCritic.
  gem "flog", "4.8.0"
  # Pinned as RubyCritic needs it on Ruby 4.
  gem "ostruct", "~> 0.6.3"
  # Generates the RDoc documentation and checks its coverage.
  gem "rdoc", "~> 8.0"
  # Rates the code's quality.
  gem "rubycritic", "~> 5.0"
  # Checks the RBS types against the code.
  gem "steep", "~> 2.1"
  # The Ruby that mise installs carries erb 6.1.0 as a default gem, which RubyGems
  # doesn't publish, so Bundler can't lock a checksum for it and a frozen install
  # refuses the lockfile. RDoc needs erb. Remove this when RubyGems has the
  # release that Ruby carries.
  gem "erb", "< 6.1"
end
