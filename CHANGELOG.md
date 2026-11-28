# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `alibi --version` prints the version of Alibi.
- `alibi --help` prints a usage line.
- Any other command line prints an error on standard error and exits with status 2.
  Alibi exits with 0 when every check passes, 1 when a check fails, and 2 on an error,
  such as a usage mistake or an alibi file that is missing or invalid.

[Unreleased]: https://github.com/setdef/Alibi/commits/trunk
