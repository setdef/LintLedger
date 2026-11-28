# frozen_string_literal: true

module ReleaseChangelog
  # One entry of a changelog's Unreleased section, with the heading it is under.
  class Entry
    MARKER = "**Breaking:**"
    # Keep a Changelog's headings, each with the change an entry under it
    # makes by Semantic Versioning, unless it is marked breaking.
    HEADINGS = {
      Added: :minor,
      Changed: :minor,
      Deprecated: :minor,
      Removed: :major,
      Fixed: :patch,
      Security: :patch,
    }.freeze

    private_constant(:MARKER)
    public_constant(:HEADINGS)

    # The heading the entry is under, as a Symbol such as :Added.
    attr_reader :heading

    # The entry's text, without its list marker.
    attr_reader :text

    # An entry with the given +heading+ and +text+.
    def initialize(heading, text)
      @heading = heading
      @text = text
    end

    # The change the entry makes to a version: :major, :minor, or :patch.
    def change
      @text.start_with?(MARKER) ? :major : HEADINGS[@heading]
    end

    # The entry as a list item.
    def to_s
      "- #{@text}"
    end
  end
end
