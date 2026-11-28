# frozen_string_literal: true

module ReleaseChangelog
  # A version of three numbers, such as 0.4.2.
  class Version
    include Comparable

    # Semantic Versioning lets a 0.y.z version change anything, so before
    # 1.0.0 each change raises the number one place lower than it would after.
    BEFORE_STABLE = { major: :minor, minor: :patch, patch: :patch }.freeze
    private_constant(:BEFORE_STABLE)

    # The first version of a project.
    def self.initial
      new(0, 1, 0)
    end

    # The version in +text+, such as "0.4.2".
    def self.parse(text)
      numbers = text.split(".").map { Integer(it, 10) }
      new(numbers.first, numbers[1], numbers[2])
    end

    # A version of the given numbers.
    def initialize(major, minor, patch)
      @major = major
      @minor = minor
      @patch = patch
    end

    # Whether the version is 1.0.0 or later.
    def stable?
      @major.positive?
    end

    # The version a release with the +change+ (:major, :minor, or :patch)
    # follows this one with.
    def after(change)
      case stable? ? change : BEFORE_STABLE[change]
      when :major then Version.new(@major + 1, 0, 0)
      when :minor then Version.new(@major, @minor + 1, 0)
      else Version.new(@major, @minor, @patch + 1)
      end
    end

    # Orders versions by their numbers.
    def <=>(other)
      numbers <=> other.numbers
    end

    # The version as "0.4.2".
    def to_s
      numbers.join(".")
    end

    protected def numbers
      [@major, @minor, @patch]
    end
  end
end
