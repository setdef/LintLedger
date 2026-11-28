# frozen_string_literal: true

desc "Type-check lib and the tasks with Steep"
task :steep do
  sh("bundle", "exec", "steep", "check")
end
