# frozen_string_literal: true

# Fledge runs from the bundle in build/, so the app it builds doesn't carry Fledge, and the app leaves out the group of
# gems that only the checks use.
FLEDGE_ENV = {
  BUNDLE_GEMFILE: File.expand_path("../build/Gemfile", __dir__),
  BUNDLE_WITHOUT: "check",
}.transform_keys(&:to_s).freeze

desc "Build Alibi for this computer with Fledge, into build/dist"
task :build do
  # build/Gemfile.lock names the Bundler that locked it, and a Bundler of another version rewrites that name in the
  # lock. Bundler switches to the locked version when it finds that version among the gems it can see, so GEM_PATH
  # points the build's Bundler at the same gems that this rake task sees.
  gem_path = (Gem.path + [Gem.default_dir]).uniq.join(File::PATH_SEPARATOR)
  env = FLEDGE_ENV.merge({ GEM_PATH: gem_path }.transform_keys(&:to_s))
  Bundler.with_unbundled_env do
    sh(env, "bundle", "install", chdir: "build")
    sh(env, "bundle", "exec", "fledge", "build", "..", chdir: "build")
  end
end
