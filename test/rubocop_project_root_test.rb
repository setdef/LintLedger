# frozen_string_literal: true

require_relative("test_helper")

# SimpleCov starts in test_helper, so it must load before the code it measures.
require_relative("../tasks/rubocop_project_root")

# Checks that RuboCop takes this repository as its project root.
class RubocopProjectRootTest < Minitest::Test
  def test_the_project_root_is_the_folder_with_the_gemfile
    assert_equal(File.expand_path("..", __dir__), RuboCop::ConfigFinder.project_root)
  end
end
