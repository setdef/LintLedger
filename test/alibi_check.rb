# frozen_string_literal: true

require "memory_project"

# Checks alibis against lib/a.rb, which holds CODE unless a test gives other text, and test/a.rb, which the glob
# doesn't match. The parser doesn't read alibis yet, so each check builds its alibi file by hand.
module AlibiCheck
  CODE = <<~RUBY
    def a
      x # TODO
    end

    def b
      x # TODO
      y # TODO # TODO
    end
  RUBY
  STALE = "matches nothing: remove it, or bring its path and snippet up to date"
  public_constant(:CODE, :STALE)

  # An alibi for the file at path, whose snippet is the given text.
  def alibi(snippet, path: "lib/a.rb", occurrence: nil)
    Alibi::AlibiFile::Alibi.new(path:, snippet: Alibi::Snippet.new(snippet), reason: "Why.", occurrence:)
  end

  # The alibis that excuse each match in CODE.
  def code_alibis
    [
      alibi("x # TODO\nend"),
      alibi("def b\nx # TODO"),
      alibi("y # TODO # TODO", occurrence: 1),
      alibi("y # TODO # TODO", occurrence: 2),
    ]
  end

  # The verdict on an alibi file whose glob is lib/**/*.rb and whose pattern is TODO, with the given alibis.
  def check(*alibis, file: CODE)
    glob = Alibi::Glob.new("lib/**/*.rb")
    alibi_file = Alibi::AlibiFile.new(glob:, pattern: Alibi::Pattern.new("TODO"), alibis:)
    alibi_file.check(MemoryProject.new(["lib/a.rb", file], ["test/a.rb", "x # TODO\n"]))
  end
end
