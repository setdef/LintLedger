# frozen_string_literal: true

namespace :bundle do
  desc "Fail when a frozen install, as CI runs it, would refuse Gemfile.lock"
  task :frozen do
    # sh takes the environment as a hash with string keys, which Style/StringHashKeys rejects as a literal.
    env = { BUNDLE_FROZEN: "true" }.transform_keys(&:to_s)
    sh(env, "bundle", "install", "--local")
  end
end
