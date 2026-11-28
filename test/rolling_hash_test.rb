# frozen_string_literal: true

require "test_helper"

class RollingHashTest < Minitest::Test
  def test_equal_runs_hash_alike_wherever_they_start
    hashes = Alibi::RollingHash.new([7, 8, 9, 7, 8])

    assert_equal(hashes.of(0, 2), hashes.of(3, 2))
    assert_equal(Alibi::RollingHash.new([7, 8]).of(0, 2), hashes.of(3, 2))
  end

  def test_runs_that_differ_hash_apart
    hashes = Alibi::RollingHash.new([0, 1, 1, 0, 0, 0])

    assert_equal(5, [hashes.of(0, 2), hashes.of(1, 2), hashes.of(2, 2), hashes.of(3, 2), hashes.of(0, 3)].uniq.size)
  end

  def test_an_empty_run_hashes_to_zero
    assert_equal(0, Alibi::RollingHash.new([4, 5]).of(1, 0))
  end
end
