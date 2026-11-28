# frozen_string_literal: true

require "rbconfig"

desc "Run Alibi, from this checkout, over every alibi file in .config/alibi"
task :alibi do
  sh(RbConfig.ruby, "-Ilib", "exe/alibi")
end
