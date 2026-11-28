# frozen_string_literal: true

module ReleaseChangelog
  # The link definitions at the foot of a changelog, with the ones a release
  # adds.
  class ChangelogFooter
    # A link's definition, such as `[0.3.2]: https://...`, at the start of a
    # line.
    DEFINITION = /\A\[(?<label>[^\]]+)\]:/
    VERSION = /\A\d+\.\d+\.\d+(?:[-+]|\z)/

    private_constant(:DEFINITION, :VERSION)

    # Whether +line+ is blank or defines a link, as a footer's lines do.
    def self.line?(line)
      line.strip.empty? || DEFINITION.match?(line)
    end

    # The label of the link that +line+ defines, or nil.
    def self.label(line)
      DEFINITION.match(line)&.[](:label)
    end

    # The footer made of +lines+, to which the +record+ adds its links.
    def initialize(lines, record)
      @lines = lines
      @record = record
    end

    # The footer's lines with the links of the release: the Unreleased link
    # compares from the release's tag, and a link goes to the release.
    def lines
      unreleased = place { it.casecmp?("Unreleased") }
      return around(unreleased, label_at(unreleased), 1) if unreleased

      # Keep a Changelog lists the Unreleased link first, above the releases'.
      around(place { VERSION.match?(it) } || @lines.size, "Unreleased", 0)
    end

    private def around(index, label, replaced)
      [*@lines.take(index), @record.unreleased_link(label), *release_link, *@lines.drop(index + replaced)]
    end

    private def release_link
      (place { it == @record.version }) ? [] : [@record.release_link]
    end

    private def place
      @lines.index { |line| ChangelogFooter.label(line)&.then { yield(it) } }
    end

    private def label_at(index)
      ChangelogFooter.label(@lines[index]).to_s
    end
  end
end
