# Plan

This file is a seed, and it is meant to disappear. It holds what was settled before the first commit. The work itself is in this repository's issues. As each line below gets its lasting home, delete it here. When nothing is left, delete the file: #3 tracks that.

Alibi keeps a project's suppressions in a ledger that people review. Without one, suppressions of ESLint, Clippy, RuboCop and similar checks pile up wherever an agent finds a check inconvenient, and the project's checks mean less each time. With a ledger, adding a suppression costs enough to deter it, and every suppression is in one place where a reviewer can't miss it.

Several projects each grew an earlier version of this idea. Alibi is one tool, good enough to replace every one of them.

## Settled

- **Anyone can install it without Ruby:** it is built with [Fledge](https://github.com/setdef/Fledge) and installed through [mise](https://mise.jdx.dev/).
- **A ledger is an internal Ruby DSL,** evaluated as Ruby. People review ledgers, and that review is what guards them.
- **Platforms are Fledge's.**
- **Moving the earlier versions over to Alibi is not part of this project.**
- **Releases happen on GitHub, freely:** tags and GitHub releases are cut whenever the trunk is ready. Versions are `0.X.Y` only, three plain integers: no prerelease form (no `-rc.1`, no `.pre.`), and no `1.0.0` or higher until the maintainer says so. Nothing goes to a registry outside GitHub (RubyGems, mise's registry, or any other) until the maintainer approves it.

Nothing else is settled. What the tool does, how a ledger reads, and how the project is set up are decided in #15 and the question issues it waits on.
