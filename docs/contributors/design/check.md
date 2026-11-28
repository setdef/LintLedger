# The check

How Alibi reaches a verdict on an alibi file, and why it is built this way, for the people who change it. The words are the [glossary](../../glossary.md)'s: alibi file, glob, pattern, project root, project file, match, and verdict.

## What the check does

For each alibi file it is given, Alibi:

1. reads the file's bytes and parses them as KDL 2 into a glob and a pattern, refusing anything else;
2. asks git for the top of the working tree that holds the alibi file, which is the project root, and for the project files under it;
3. keeps the project files the glob matches, reads each one as UTF-8 with LF line breaks, and runs the pattern over its whole text;
4. reaches a verdict: a pass when there is no match, a failure otherwise, and an error when the glob matched no file;
5. prints the verdict, and returns an exit status. Over several alibi files, the highest status wins: 2 for an error, then 1 for a failure, then 0.

## How the pieces fit

The decisions sit in objects that do no I/O, and the I/O sits at the edges, in objects that hand the core plain values:

| Object | Its one job | Does I/O |
| --- | --- | --- |
| `CommandLine` | Turns a command line into alibi files to check, checks each, and picks the exit status. | Reads alibi files; writes to the two streams |
| `Request` | Reads the options and the names of the alibi files from the arguments. | No |
| `AlibiFile` | Holds a glob and a pattern, and checks a project against them, refusing a project the glob matches no file in. | No |
| `AlibiFile::Parser`, `AlibiFile::Node` | Turn an alibi file's KDL into an `AlibiFile`, refusing anything else in it. | No |
| `Glob` | Chooses, among a project's paths, the ones the alibi file applies to. | No |
| `Pattern` | Compiles and vets the regexp: it refuses one that can match empty text or can't match in linear time. | No |
| `ProjectFile` | Decodes one file's bytes and finds a regexp's matches in its text. | No |
| `Match` | One match, shown as `PATH:LINE: TEXT`. | No |
| `Verdict` | The files checked and the matches in them. | No |
| `Project` | Lists a git working tree's project files, and reads one. | Runs git; reads files |
| `Report` | Writes a verdict for a person or a log. | Writes to the stream it is given |

`AlibiFile#check` takes any object with `paths` and `file(path)`, the `_Project` interface in `sig/alibi/alibi_file.rbs`, and `CommandLine` takes any object with `containing(folder)`. `Project` is the real one. The tests pass `MemoryProject` (in `test/memory_project.rb`), which holds its files in memory, so everything but `Project` and the executable is tested without a subprocess. Only `ProjectTest`, which builds one working tree for all its tests, and `ExecutableTest`, one run of `exe/alibi` for each exit status, start git or Ruby.

## Why it is shaped this way

**Objects answer questions instead of handing out their fields.** `Verdict#passed?`, `Verdict#files_checked`, and `Match#to_s` give the caller what it asks for, and no class has an attribute reader. This is the project's style under its gates as well as a design choice: Steep, with every diagnostic an error, counts only a `def` as a method's implementation, so a reader from `attr_reader` or `Data.define` would need a `# @dynamic` annotation, which switches off Steep's check that the method exists; and RuboCop's `Style/TrivialAccessors` flags a `def` that only returns an instance variable.

**KDL is read as KDL 2, always.** Without `version: 2`, the kdl gem reads a document it can't parse as KDL 2 as KDL 1, so a typo could make an alibi file mean something else. Without `parse_types: false`, it turns a value with a type annotation, such as `(regex)"…"`, into an object of that type; with it, the parser sees the annotation and refuses it. A KDL syntax error keeps the gem's message, which ends with the line and column.

**Git chooses the files.** `git ls-files --cached --others --exclude-standard` lists the files git tracks and the untracked ones it doesn't ignore, so a new file counts before anyone stages it, and build output in an ignored folder is never read. Alibi skips a path that is no longer a regular file (a tracked file someone deleted, or a submodule) and never follows a symlink, so it reads nothing outside the project root. A glob that is absolute or has a `..` segment is refused on every system, a Windows drive such as `C:` included, so an alibi file gets the same verdict wherever it is checked.

**A pattern can't hang Alibi.** Alibi refuses a regexp unless `Regexp.linear_time?` is true for it. That keeps the verdict from depending on how fast the machine is, which a timeout alone would not. Lookahead and lookbehind stay, which RE2's syntax would have dropped, and the build needs no native extension, which RE2 would bring to every platform. The 2-second timeout on each file is a backstop that a linear-time pattern reaches only on an enormous file.

**A glob that matches no file is an error.** An alibi file that checks nothing passes whatever the project holds, so a mistyped glob would leave a ban unenforced, unseen, for as long as nobody looks. Alibi refuses a bare `alibi` with no alibi file to run for the same reason. It is a fact about the alibi file and a project together, since the same glob matches in one project and none in another, so `AlibiFile#check` decides it, from the paths the project lists; `Glob` knows only its text, and `Verdict` only reports what was checked.

**A pattern that can match empty text is an error.** Alibi tests that by matching the compiled regexp against an empty string, which is true of every pattern that can match nothing, such as `a*`, `^`, or `(?:a|)`. Such a pattern matches at every position of every file, so it fails on every line, and no match in it can be the one that someone meant. It is a fact about the pattern alone, so `Pattern` refuses it where it vets the regexp, with the other refused patterns, before any file is read.

**Text is the same on every system.** Each file is read as UTF-8, and each CRLF becomes LF before matching, so a Windows checkout with `core.autocrlf` gets the Linux verdict, and a pattern can end a line with `\n` or `$` either way. A file that isn't valid UTF-8 is an error, with the file's path in its message: a glob that matches binary files is a mistake in the alibi file.

**An error outweighs a failure, and doesn't stop the run.** `CommandLine` reports an error in one alibi file and checks the rest, so one broken file doesn't hide the verdicts of the others. The exit statuses are ordered by how much they need a person: 2 means the check itself couldn't run, and 1 that it ran and found something.

## Traps

- **This project's alibi files contain what they ban,** and so do the samples that test them. `bundle exec rake` runs `exe/alibi` over the alibi files in `.config/alibi/`, whose globs match only Ruby, RBS, and the files Bundler, Rake, and Steep read. The alibi files themselves are KDL, and each sample is a `.txt` file under `test/fixtures/`, so the check never reads them. `test/alibi_files_test.rb` reads the samples for each alibi file: a path its glob has to match, the forms its pattern has to find, and lines it has to leave alone. A new alibi file there needs a folder of samples too, or that test fails. Markdown is left out of the globs, since its prose names the very forms they ban.
- **`.` doesn't match a line break** unless the pattern starts with `(?m)`, and `^` and `$` match at every line, as Ruby has them.
- **`ProjectFile#matches` reads `Regexp.last_match` inside `to_enum(:scan, regexp)`,** which gives each match's position without a hand-written loop that has to step past empty matches. It takes the offset from `pre_match.length`, since RBS types `MatchData#begin` as possibly nil.
- **Paths in the output start at the project root,** not the folder where Alibi runs. A bare `alibi`, on the other hand, looks for `.config/alibi/` in the folder where it runs, not at the project root.
- **On Windows, git checks a symlink out as a plain file** when `core.symlinks` is false, so Alibi reads it there as a file whose text is the path of its target.
- **A file's text reaches the terminal.** `Report` shows every control character but a tab as an escape, so a file can't move the cursor or set the terminal's title.

## What the check doesn't do

- **Read alibis.** An `alibi` node, with its snippet, reason, and occurrence, is an error until the next slice of [#24](https://github.com/setdef/Alibi/issues/24) builds them; until then, an alibi file passes only while its pattern matches nothing.
- **Look further for alibi files.** A bare `alibi` reads only `*.kdl` files directly in `.config/alibi/`, with no folders below it and no search upward.
- **Take more than one glob or pattern in an alibi file,** or flags for the pattern outside the pattern itself.
- **Read a file outside the project root,** an ignored file, a file inside a submodule, or a file through a symlink.
- **Print color, or any format but lines of text.**
