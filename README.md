# Alibi

Alibi fails your build when a pattern you ban, such as `# rubocop:disable`, turns up in your project's files.

Every linter, type checker, and compiler lets someone switch a check off at one place in the code, and each such place is easy to miss in review. Alibi puts them on the record. You write an alibi file for each thing you ban: the files it applies to, and a regular expression that finds it. Alibi runs the regular expression over those files and lists every match. It works on files in any language, has no built-in knowledge of any linter, and takes no plugins, so the same alibi file can ban a suppression comment, a setting in a configuration file, or any other text.

Alibis, which will excuse one match with the reason it is needed, aren't available yet. Until they are, an alibi file passes only while its pattern matches nothing.

Until Alibi 1.0.0, a minor version (0.X.0) may change what an alibi file may hold, and [`CHANGELOG.md`](CHANGELOG.md) says what changed. [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html) allows this: in a 0.y.z version, "Anything MAY change at any time."

## A first example

This alibi file, saved as `.config/alibi/rubocop-disable-never.kdl` in a project's git working tree, bans [RuboCop](https://rubocop.org/)'s `disable` and `todo` comments in every Ruby file:

```kdl
// RuboCop's checks hold everywhere in this project: fix the code instead.
files "**/*.rb"
pattern #"#\s*rubocop\s*:\s*(disable|todo)\b"#
```

With one such comment in `lib/invoice.rb`, Alibi fails and prints the name of the alibi file and the line with the match:

```console
$ alibi
.config/alibi/rubocop-disable-never.kdl: failed: 1 match in 1 file
lib/invoice.rb:2:   def total(lines) # rubocop:disable Metrics/AbcSize
```

Once the comment is gone, it passes, and says how many files it checked:

```console
$ alibi
.config/alibi/rubocop-disable-never.kdl: passed: no matches in 1 file
```

## Install

Alibi installs through [mise](https://mise.jdx.dev/) from its [GitHub releases](https://github.com/setdef/Alibi/releases). Each release has a build for each platform, and each build includes Ruby, so your computer needs none. Put this in a project's `mise.toml`, or in `~/.config/mise/config.toml` for every project, and run `mise install`:

```toml
[tools."github:setdef/Alibi"]
version = "latest"
strip_components = 1
bin_path = "."

[tools."github:setdef/Alibi".platforms]
macos-arm64 = { asset_pattern = "alibi-arm64-darwin.tar.gz" }
linux-x64 = { asset_pattern = "alibi-x86_64-linux.tar.gz" }
linux-arm64 = { asset_pattern = "alibi-aarch64-linux.tar.gz" }
windows-x64 = { asset_pattern = "alibi-x64-mingw-ucrt.zip" }
windows-arm64 = { asset_pattern = "alibi-aarch64-mingw-ucrt.zip" }
```

`mise exec -- alibi --version` then prints the installed version. With `strip_components` and `bin_path`, mise puts the `alibi` program on your `PATH` and leaves out the Ruby that comes in the build. Without them, mise puts that Ruby first on your `PATH`, ahead of any Ruby you use.

With mise 2026.10.11 and newer, mise's github backend applies a default `minimum_release_age` of 24 hours when it resolves `latest`, so `version = "latest"` installs the newest release that is at least a day old. To install a release sooner, write that release's number in place of `latest`, as in `version = "X.Y.Z"`: mise doesn't filter an exact version.

On Linux with [musl](https://musl.libc.org/), such as [Alpine](https://alpinelinux.org/), use the musl builds:

```toml
[tools."github:setdef/Alibi"]
version = "latest"
strip_components = 1
bin_path = "."

[tools."github:setdef/Alibi".platforms]
linux-x64 = { asset_pattern = "alibi-x86_64-linux-musl.tar.gz" }
linux-arm64 = { asset_pattern = "alibi-aarch64-linux-musl.tar.gz" }
```

| Platform | Runs on |
| --- | --- |
| `arm64-darwin` | macOS 14 or newer, on Apple silicon |
| `x86_64-linux`, `aarch64-linux` | Linux with glibc 2.39 or newer, such as Ubuntu 24.04 |
| `x86_64-linux-musl`, `aarch64-linux-musl` | Linux with musl |
| `x64-mingw-ucrt`, `aarch64-mingw-ucrt` | Windows 11, on x64 or ARM64 |

Alibi runs `git` to find a project's files, so it needs `git` on the `PATH`.

## Usage

### Running Alibi

`alibi FILE.kdl` checks one alibi file, and `alibi A.kdl B.kdl` checks each in turn. A bare `alibi` checks every `*.kdl` file directly in `.config/alibi/` of the folder you run it in, in order of name, so a new alibi file there runs without anyone adding it to a command line. Keep one alibi file for each thing you ban, named for what it bans and to what bar, such as `rubocop-disable-never.kdl`.

For each alibi file, Alibi prints one line on standard output with the alibi file's name, whether it passed, and how many files it checked. After a failure, it prints each match as `PATH:LINE: TEXT`, with the path from the project root and the whole line where the match starts. Alibi prints no color. It shows a control character from a file, other than a tab, as an escape such as `\x1B`, and does the same for each character that changes the order of the text around it or breaks the line: a bidirectional override or isolate, and the line and paragraph separators.

Errors go to standard error, one line each, starting with `alibi:` and the alibi file's name. After an error in one alibi file, Alibi still checks the rest.

| Exit status | When |
| --- | --- |
| 0 | Every alibi file passed, or the command line was `--version` or `--help`. |
| 1 | An alibi file failed, and none had an error. |
| 2 | An error: a command line Alibi can't use; an alibi file that is missing, unreadable, or isn't valid; a glob that matches no file; a pattern Alibi refuses; an alibi file outside a git working tree; a matched file that isn't UTF-8 text; or a bare `alibi` with no `*.kdl` file in `.config/alibi/`. |

### Writing an alibi file

An alibi file is [KDL 2](https://kdl.dev/) with exactly two nodes, each with one string argument and nothing else:

- `files` is a glob of the files the alibi file applies to.
- `pattern` is a [Ruby regular expression](https://docs.ruby-lang.org/en/master/Regexp.html) that finds what the alibi file bans.

Comments start with `//`. A raw string such as `#"\s*"#` takes no escapes, so a pattern can be written as Ruby would read it. Anything else in the file, such as another node, a second `files` node, an argument that isn't a string, a property, a child node, or a type annotation, is an error. So is an `alibi` node, until a later version reads alibis.

**The glob** starts from the project root: the top of the git working tree that holds the alibi file, wherever the alibi file sits in it. `*` matches any part of a name, `**/` matches any number of folders, and braces list alternatives, as in `{lib,test}/**/*.rb`. A `*` also matches a name that starts with a dot. Write `/` between folders on every system. A glob that is absolute, such as `/etc/*` or `C:/src/*`, or that has a `..` segment or a null character, is an error.

Alibi matches the glob against the files git tracks and the files git would track: untracked files that no `.gitignore` lists. A new file counts before anyone stages it, and ignored build output never does. Alibi never follows a symlink, and skips a tracked file that has been deleted. A glob that matches no file is an error, since an alibi file that checks nothing most likely has a mistyped glob.

**The pattern** is a regular expression that Alibi runs over each file's whole text, so it can span lines. A match on several lines is shown at the line where it starts. A pattern has no flags in the alibi file; write them inline, such as `(?i)` to ignore case or `(?m)` to let `.` match a line break.

Alibi refuses a pattern that can match empty text, such as `a*` or `^`, because it would match at every position of every file; write it so that every match has at least one character. Alibi also refuses a pattern that Ruby can't match in linear time, so no pattern can hang it. Back-references, captures inside lookarounds, nested quantifiers, the absence operator, and conditionals make a pattern slower than that. Lookahead and lookbehind are allowed. As a backstop, a pattern that runs for more than 2 seconds over one file is an error.

Alibi reads each file as UTF-8 and reads each CRLF line break as LF, so a Windows checkout gets the same verdict as a Linux one. A file the glob matches that isn't valid UTF-8, such as an image, is an error: write the glob so that it matches only text files.

## Documentation

- [`CHANGELOG.md`](CHANGELOG.md) lists what changed in each release.
- [`docs/glossary.md`](docs/glossary.md) defines the words Alibi uses, such as alibi file, glob, pattern, and match.

## Reporting problems

Open an issue at [github.com/setdef/Alibi/issues](https://github.com/setdef/Alibi/issues) with the alibi file, the command you ran, what Alibi printed, and its exit status.

## Contributing

[`CONTRIBUTING.md`](CONTRIBUTING.md) has the rules for changing Alibi, and [`docs/contributors/design/check.md`](docs/contributors/design/check.md) explains how the check works.

## License

Alibi's code is under the [MIT License](LICENSE), and its documentation under [CC BY 4.0](LICENSES/CC-BY-4.0.txt), copyright setdef.

## How this was made

I use three words for how code and prose comes to exist. Code or prose I wrote, I typed by hand, with nothing generated. Code or prose I wrought, an AI agent generated while I iterated with it, and I reviewed every change before committing it, so I take responsibility for every diff. Code or prose I requested, an agent built with little or no review from me, in the style of a "dark factory."

Alibi's code, tests, and documentation, this README included, were requested. Agents built them from my goals and decisions. In place of review, the project's rules require every change to be test-driven, every line and branch to be covered by tests on every system CI runs, and every change to pass RuboCop, Steep, RubyCritic, RDoc coverage, `reuse lint`, and Alibi's own check that the project switches none of those checks off before it lands. [declare-ai.org](https://declare-ai.org/1.0.0/total.html).
