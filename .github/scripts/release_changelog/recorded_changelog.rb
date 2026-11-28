# frozen_string_literal: true

require_relative "changelog"
require_relative "changelog_footer"
require_relative "changelog_layout"
require_relative "line_blocks"
require_relative "text_lines"
require_relative "unreleased_section"

module ReleaseChangelog
  # Trunk's changelog with a release recorded in it: a dated heading over the
  # entries the release listed, which leave Unreleased, and the link
  # definitions of the release.
  class RecordedChangelog
    # The changelog in +text+, with the +record+ of a release.
    def initialize(text, record)
      @text = TextLines.new(text)
      @lines = @text.to_a
      @record = record
      @start = @lines.index { Changelog::UNRELEASED.match?(it) }
    end

    # What is wrong with the changelog, as a phrase that follows its name, or nil.
    def problem
      "has no ## [Unreleased] heading" unless @start
    end

    # The recorded changelog's text.
    def to_s
      layout = ChangelogLayout.new(@lines, @start)
      @text.join(
        LineBlocks.join(
          [@lines[layout.head].to_a, unreleased(layout), @record.section, @lines[layout.older].to_a, footer(layout)]
        )
      )
    end

    private def unreleased(layout)
      UnreleasedSection.new(@lines, layout.visible, layout.unreleased).without(@record.listed_texts)
    end

    private def footer(layout)
      ChangelogFooter.new(LineBlocks.trim(@lines.drop(layout.footer)), @record).lines
    end
  end
end
