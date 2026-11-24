# Plan

This file is a seed, and it is meant to disappear. It holds what was settled before the first commit. The work itself is in this repository's issues. As each line below gets its lasting home, delete it here. When nothing is left, delete the file: #3 tracks that.

LintLedger keeps a project's lint exceptions in a ledger that people review. Without one, exceptions to ESLint, Clippy, RuboCop and the like pile up wherever an agent finds a rule inconvenient, and the project's checks mean less each time. A ledger makes adding an exception costly enough to deter it, and puts every exception in one place where a reviewer can't miss it.

Several projects each grew their own copy of this idea. LintLedger is one tool, good enough to replace every one of them.

## Settled

- **It checks files in any language.** It is not tied to one language or one linter.
- **It is written in Ruby.**
- **Anyone can install it without Ruby:** it is built with [Fledge](https://github.com/setdef/Fledge) and installed through [mise](https://mise.jdx.dev/).
- **Names:** the project is LintLedger; the gem is `lint_ledger` and its module `LintLedger`; the command is `lint-ledger`.
- **A ledger is an internal Ruby DSL,** evaluated as Ruby. People review ledgers, and that review is what guards them.
- **Platforms are Fledge's.**
- **License:** MIT. Copyright setdef.
- **Its own quality bar:** this project holds itself to the tools and settings that [ruby_quality](https://github.com/Kerrick/ruby_quality) uses to enforce quality, whether or not it uses that repository to get them. It checks its own exceptions with itself.
- **Moving the earlier copies over to LintLedger is not part of this project.**
- **Releases happen on GitHub, freely:** tags and GitHub releases are cut whenever the trunk is ready. Versions are `0.X.Y` only, three plain integers: no prerelease form (no `-rc.1`, no `.pre.`), and no `1.0.0` or higher until the maintainer says so. Nothing goes to a registry outside GitHub (RubyGems, mise's registry, or any other) until the maintainer approves it.

Nothing else is settled. What the tool does, how a ledger reads, and how the project is set up are decided through #1 and #15.
