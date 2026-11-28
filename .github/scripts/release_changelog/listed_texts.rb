# frozen_string_literal: true

module ReleaseChangelog
  # The texts of the entries a release lists, which each take away one entry
  # of the same text from Unreleased.
  class ListedTexts
    # The texts of the +changes+ a release lists.
    def initialize(changes)
      @counts = changes.map(&:text).tally
    end

    # Whether +item+ is a list item whose text the release lists and has not
    # taken away yet. A true answer uses up one listing of the text.
    def take?(item)
      return false unless item.item?

      text = item.text
      taken = @counts.fetch(text, 0).positive?
      @counts[text] -= 1 if taken
      taken
    end
  end
end
