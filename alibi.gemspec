# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "alibi"
  # Bundler evaluates this file before the tests start SimpleCov, so it reads
  # the version as text. Requiring lib/alibi/version would run its lines
  # before coverage measures them.
  spec.version = File.read(File.expand_path("lib/alibi/version.rb", __dir__))[/VERSION = "([^"]+)"/, 1]
  spec.authors = ["setdef"]
  spec.email = ["kerrick@setdef.com"]
  spec.summary = "Check files in any language against an alibi file that records each suppression and its reason."
  spec.description = spec.summary
  spec.homepage = "https://github.com/setdef/Alibi"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 4.1.0.a"

  # Reads an alibi file, which is KDL 2.
  spec.add_dependency("kdl", "~> 2.2")

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/trunk/CHANGELOG.md"

  spec.files = Dir["lib/**/*.rb", "sig/**/*.rbs", "exe/*", "CHANGELOG.md", "LICENSE"]
  spec.bindir = "exe"
  spec.executables = ["alibi"]
  spec.require_paths = ["lib"]
end
