# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Each GitHub release carries a build of Alibi for macOS on Apple silicon, Linux with glibc or musl on x86-64 and
  ARM64, and Windows on x64 and ARM64, and `mise` installs it from there. The build includes its own Ruby, so the
  computer needs none.
- `alibi --version` prints the version of Alibi.
- `alibi --help` prints a usage line.
- `alibi FILE.kdl` checks an alibi file: it runs the file's `pattern`, a Ruby regular expression, over each file
  that its `files` glob matches in the git working tree that holds it, and lists each match as `PATH:LINE: TEXT`.
  The glob matches among the files git tracks and the untracked ones it doesn't ignore. An alibi file passes when
  its pattern matches nothing. `alibi A.kdl B.kdl` checks each one.
- A bare `alibi` checks every `*.kdl` file directly in `.config/alibi/`.
- An alibi file is KDL 2 with one `files` node and one `pattern` node, each with one string. Anything else in it is
  an error, and so is an `alibi` node: this version doesn't read alibis.
- Alibi refuses a pattern that Ruby can't match in linear time, and stops a pattern that runs for more than 2
  seconds over one file.
- Alibi reads each file as UTF-8, with CRLF line breaks as LF.
- Alibi exits with 0 when every alibi file passes, 1 when one fails, and 2 on an error, which outweighs a failure:
  a command line it can't use, an alibi file that is missing, unreadable, or invalid, a pattern it refuses, an
  alibi file outside a git working tree, a matched file that isn't UTF-8 text, or a bare `alibi` with no `*.kdl`
  file in `.config/alibi/`.

[Unreleased]: https://github.com/setdef/Alibi/commits/trunk
