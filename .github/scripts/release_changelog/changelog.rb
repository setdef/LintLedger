# frozen_string_literal: true

require_relative "change_group"
require_relative "changes"
require_relative "visible_lines"

module ReleaseChangelog
  # A changelog in Keep a Changelog's form, read for its Unreleased section.
  class Changelog
    UNRELEASED = /\A## \[Unreleased\]\s*\z/
    # The section ends at the next heading of level 1 or 2, such as a
    # release's `## [0.3.2] - 2026-11-02`.
    SECTION_END = /\A##?(?:\s|\z)/

    # The mark that some editors put at the start of a UTF-8 file.
    BYTE_ORDER_MARK = "\uFEFF"

    public_constant(:UNRELEASED, :SECTION_END, :BYTE_ORDER_MARK)

    # The changelog in +text+.
    def initialize(text)
      @lines = text.delete_prefix(BYTE_ORDER_MARK).lines(chomp: true)
      start = @lines.index { UNRELEASED.match?(it) }
      @section = start && VisibleLines.new(@lines.drop(start + 1)).take_while { !SECTION_END.match?(it) }
    end

    # Whether the changelog has a heading for the release of +version+.
    def released?(version)
      @lines.any? { it.match?(/\A## \[#{Regexp.escape(version.to_s)}\](?:\s|\z)/) }
    end

    # What is wrong with the changelog, as a phrase that follows its name, or nil.
    def problem
      return "has no ## [Unreleased] heading" unless @section

      groups.lazy.filter_map(&:problem).first
    end

    # The entries under Unreleased.
    def changes
      Changes.new(groups.flat_map(&:entries))
    end

    private def groups
      (@section || []).slice_before(ChangeGroup::HEADING).map { ChangeGroup.new(it) }
    end
  end
end
