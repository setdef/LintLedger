# frozen_string_literal: true

require "minitest/test_task"

# SimpleCov starts in test/test_helper.rb, so the tests load it before the code under test,
# and fails the run below 100% of the lines and branches, overall and in each file.
Minitest::TestTask.create(:test) do |task|
  task.test_prelude = %(require "test/test_helper")
  task.test_globs = ["test/**/*_test.rb"]
end
