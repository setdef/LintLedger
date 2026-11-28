# frozen_string_literal: true

require "test_helper"

class GlobTest < Minitest::Test
  def test_two_stars_match_any_number_of_folders
    assert_equal(
      ["lib/alibi.rb", "lib/alibi/glob.rb"],
      select("lib/**/*.rb", "lib/alibi.rb", "lib/alibi/glob.rb", "test/glob_test.rb")
    )
  end

  def test_one_star_stays_inside_one_folder
    assert_equal(["alibi.gemspec"], select("*", "alibi.gemspec", "lib/alibi.rb"))
  end

  def test_braces_list_alternatives
    assert_equal(["lib/alibi.rb", "exe/alibi"], select("{lib,exe}/*", "lib/alibi.rb", "exe/alibi", "test/a.rb"))
  end

  def test_a_star_matches_a_name_that_starts_with_a_dot
    assert_equal([".github/workflows/ci.yml"], select("**/*.yml", ".github/workflows/ci.yml"))
  end

  def test_an_absolute_glob_is_an_error
    ["/etc/*", "\\\\server\\share\\*", "C:/Users/*", "c:\\x", "~/notes/*"].each do |text|
      error = assert_raises(Alibi::Error) { Alibi::Glob.new(text) }

      assert_equal("the glob #{text.inspect} is absolute: write it relative to the project root", error.message)
    end
  end

  def test_a_glob_that_climbs_out_of_the_project_is_an_error
    ["../*.rb", "lib/../../*", "lib\\..\\x"].each do |text|
      error = assert_raises(Alibi::Error) { Alibi::Glob.new(text) }

      assert_equal("the glob #{text.inspect} has a \"..\" segment: write it inside the project root", error.message)
    end
  end

  def test_a_glob_with_a_null_character_is_an_error
    error = assert_raises(Alibi::Error) { Alibi::Glob.new("lib/a\0b") }

    assert_equal("the glob \"lib/a\\u0000b\" has a null character: remove it", error.message)
  end

  def test_two_dots_inside_a_name_are_allowed
    assert_equal(["docs/a..b/x.md"], select("docs/a..b/*.md", "docs/a..b/x.md"))
  end

  def test_shows_as_its_text
    assert_equal("lib/**/*.rb", Alibi::Glob.new("lib/**/*.rb").to_s)
  end

  private def select(glob, *paths)
    Alibi::Glob.new(glob).select(paths)
  end
end
