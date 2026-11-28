# The check

How Alibi reaches a verdict on an alibi file, and why it is built this way, for the people who change it. The words are the [glossary](../../glossary.md)'s: alibi file, glob, pattern, project root, project file, match, verdict, alibi, snippet, occurrence, reason, unexcused match, stale alibi, and ambiguous alibi.

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
| `AlibiFolder` | Names the alibi files in a folder's `.config/alibi/`, for a bare `alibi`. | Lists the folder |
| `Request` | Reads the options and the names of the alibi files from the arguments. | No |
| `AlibiFileReader` | Reads an alibi file's bytes, and says in plain words why it can't. | Reads the file |
| `AlibiFile` | Holds a glob, a pattern, and alibis, and checks a project against them, refusing a project the glob matches no file in. | No |
| `AlibiFile::Parser`, `AlibiFile::Node` | Turn an alibi file's KDL into an `AlibiFile`, refusing anything else in it. | No |
| `AlibiFile::Alibi` | One alibi: says which match it excuses, or why it excuses none. | No |
| `Glob` | Chooses, among a project's paths, the ones the alibi file applies to. | No |
| `Pattern` | Compiles and vets the regexp: it refuses one that can match empty text or can't match in linear time. | No |
| `ProjectFile` | Decodes one file's bytes, finds a regexp's matches in its text, and indexes its lines for snippets. | No |
| `Lines` | Tells which line, and what text, a byte offset in a text is on. | No |
| `Match` | One match, by the lines it starts and ends on, shown as `PATH:LINE: TEXT`. | No |
| `Snippet` | An alibi's lines without their indent, and the places they occur in a file. | No |
| `SnippetIndex` | A file's lines, numbered and hashed so that finding a snippet costs the snippet's length. | No |
| `RollingHash` | The hash of any run of numbers in a sequence, in constant time. | No |
| `CheckedFiles`, `CheckedFile` | The files the glob matched, each with its index and its matches, indexed only when an alibi names one. | No |
| `SnippetMatches` | The matches a snippet holds, and which one the occurrence picks. | No |
| `Excuses` | Collects the match each alibi excuses, and why each other alibi excuses none. | No |
| `Verdict` | The files checked, the matches in them, and what the alibis excuse; it fails on each match without exactly one alibi and each alibi without one match. | No |
| `Project` | Lists a git working tree's project files, and reads one. | Runs git; reads files |
| `Report` | Writes a verdict for a person or a log. | Writes to the stream it is given |
| `Count` | A number with the word for one thing or several, as a report writes it. | No |
| `Escaped` | Shows a text from the project, such as a path, a line, or an error message that quotes one, so it is safe to print. | No |

`AlibiFile#check` takes any object with `paths` and `file(path)`, the `_Project` interface in `sig/alibi/alibi_file.rbs`, and `CommandLine` takes any object with `containing(folder)`. `Project` is the real one. The tests pass `MemoryProject` (in `test/memory_project.rb`), which holds its files in memory, so everything but `Project` and the executable is tested without a subprocess. Only `ProjectTest`, which builds one working tree for all its tests, and `ExecutableTest`, one run of `exe/alibi` for each exit status, start git or Ruby.

## Why it is shaped this way

**Objects answer questions instead of handing out their fields.** `Verdict#passed?`, `Verdict#files_checked`, and `Match#to_s` give the caller what it asks for, and no class has an attribute reader. This is the project's style under its gates as well as a design choice: Steep, with every diagnostic an error, counts only a `def` as a method's implementation, so a reader from `attr_reader` or `Data.define` would need a `# @dynamic` annotation, which switches off Steep's check that the method exists; and RuboCop's `Style/TrivialAccessors` flags a `def` that only returns an instance variable.

**KDL is read as KDL 2, always.** Without `version: 2`, the kdl gem reads a document it can't parse as KDL 2 as KDL 1, so a typo could make an alibi file mean something else. Without `parse_types: false`, it turns a value with a type annotation, such as `(regex)"…"`, into an object of that type; with it, the parser sees the annotation and refuses it. A KDL syntax error keeps the gem's message, which ends with the line and column.

**Git chooses the files.** `git ls-files --cached --others --exclude-standard` lists the files git tracks and the untracked ones it doesn't ignore, so a new file counts before anyone stages it, and build output in an ignored folder is never read. Alibi skips a path that is no longer a regular file (a tracked file someone deleted, or a submodule) and never follows a symlink, so it reads nothing outside the project root. Every call to git carries `-c core.fsmonitor=false`, because a checkout's config can set `core.fsmonitor` to a command that git runs when it reads the index, and a clone that someone else wrote is untrusted. Git's documentation for version 2.53 names no other setting that makes `ls-files` or `rev-parse` run a command: `core.pager` and `pager.<cmd>` start a pager only when git writes to a terminal, and Alibi reads git's output through a pipe. A glob that is absolute or has a `..` segment is refused on every system, a Windows drive such as `C:` included, so an alibi file gets the same verdict wherever it is checked.

**A pattern can't hang Alibi.** Alibi refuses a regexp unless `Regexp.linear_time?` is true for it. That keeps the verdict from depending on how fast the machine is, which a timeout alone would not. Lookahead and lookbehind stay, which RE2's syntax would have dropped, and the build needs no native extension, which RE2 would bring to every platform. The 2-second timeout on each file is a backstop that a linear-time pattern reaches only on an enormous file.

**A glob that matches no file is an error.** An alibi file that checks nothing passes whatever the project holds, so a mistyped glob would leave a ban unenforced, unseen, for as long as nobody looks. Alibi refuses a bare `alibi` with no alibi file to run for the same reason. It is a fact about the alibi file and a project together, since the same glob matches in one project and none in another, so `AlibiFile#check` decides it, from the paths the project lists; `Glob` knows only its text, and `Verdict` only reports what was checked.

**A pattern that can match empty text is an error.** Alibi tests that by matching the compiled regexp against an empty string, which is true of every pattern that can match nothing, such as `a*`, `^`, or `(?:a|)`. Such a pattern matches at every position of every file, so it fails on every line, and no match in it can be the one that someone meant. It is a fact about the pattern alone, so `Pattern` refuses it where it vets the regexp, with the other refused patterns, before any file is read.

**Text is the same on every system.** Each file is read as UTF-8, and each CRLF becomes LF before matching, so a Windows checkout with `core.autocrlf` gets the Linux verdict, and a pattern can end a line with `\n` or `$` either way. A file that isn't valid UTF-8 is an error, with the file's path in its message: a glob that matches binary files is a mistake in the alibi file.

**An error outweighs a failure, and doesn't stop the run.** `CommandLine` reports an error in one alibi file and checks the rest, so one broken file doesn't hide the verdicts of the others. The exit statuses are ordered by how much they need a person: 2 means the check itself couldn't run, and 1 that it ran and found something.

## How an alibi finds its match

The parser doesn't read alibis yet. The format of an `alibi` node, with its `snippet`, `reason`, and `occurrence`, is proposed on [#38](https://github.com/setdef/Alibi/issues/38) and not yet accepted, and what Alibi checks in a reason is open on [#11](https://github.com/setdef/Alibi/issues/11). So the engine is built by branch by abstraction: `AlibiFile.new` takes alibis, only tests pass any, and `AlibiFile.parse` refuses an `alibi` node as it always has, so every alibi file anyone can write is checked as [What the check does](#what-the-check-does) says. The engine meanwhile follows the decisions on [#4](https://github.com/setdef/Alibi/issues/4), [#5](https://github.com/setdef/Alibi/issues/5), [#6](https://github.com/setdef/Alibi/issues/6), and [#7](https://github.com/setdef/Alibi/issues/7).

An alibi has a path from the project root, a snippet, a reason, and an optional occurrence. After the pattern has run, `AlibiFile#check` takes each alibi in the order the alibi file lists them:

1. It looks up the alibi's file among the files the glob matched. A path the glob doesn't match counts as an empty file.
2. It finds where the snippet occurs in the file, comparing line by line, with each line's leading whitespace ignored on both sides. A snippet that occurs nowhere makes the alibi stale, and one that occurs more than once makes it ambiguous; either way, the alibi excuses nothing.
3. It takes the matches that start and end within the lines the snippet covers. The alibi excuses the only one, or the one its occurrence counts to, from 1. A snippet that holds no match, or several when the alibi has no occurrence, or fewer than its occurrence counts to, excuses nothing.

The verdict then counts the alibis that excuse each match. A match fails with none, as an unexcused match, and with more than one. Each alibi that excuses nothing fails too, on a line that says why and what to do.

**A snippet is lines, compared whole.** Ignoring the indent means reindenting code doesn't make an alibi stale, as #5 decided; anything else on a line counts, trailing whitespace included, because a change there is a change to the code the reason was written about.

**Finding a snippet costs the snippet's length, not the file's.** `SnippetIndex` gives each distinct line of a file, without its indent, a number, so comparing two lines costs the same however long they are. For each number of lines that some snippet has, it hashes every run of that many lines once, with `RollingHash`: the polynomial hash of Rabin and Karp's string search, taken over line numbers and kept as the hash of each prefix of the file, so each run's hash costs a multiplication and a subtraction. The index then looks up the snippet's hash and compares the runs that share it in full, stopping at the second equal one, which is all an ambiguous alibi's message needs. A file costs its lines once for each distinct snippet size, and each alibi costs its snippet's length. The options set aside:

- **Searching the file once for each alibi** costs the alibis times the file's length, the same shape as counting lines for each match, which made the check look like a hang before `Lines` replaced it.
- **An index of the lines where each line occurs**, checking each place of a snippet's first or rarest line, degrades the same way on files of repeated lines, such as Ruby's `end`.
- **Aho and Corasick's automaton over all of a file's snippets** reports every place each snippet occurs, so a snippet that occurs a thousand times costs a thousand, where two are enough.
- **A suffix automaton** bounds every search by the snippet's length too, at a hash table for each of up to twice as many states as the file has lines, and several times the code.

The modulus, `2**31 - 1`, keeps every product under `2**62`, so the arithmetic never leaves Ruby's fixed-size integers. Equal hashes are compared in full, so a collision costs a comparison and never a wrong place.

**The matches in a snippet are found by binary search.** A file's matches are in the order they start, so `CheckedFile` bounds the ones that start within a snippet's lines with two searches, and keeps those that also end there. Scanning every match for each alibi would cost the matches squared in a file with many of both.

**A collector gathers what each alibi excuses.** `AlibiFile::Alibi#claim` hands `Excuses` either the match it excuses or the line saying why it excuses none, and the verdict counts each match's alibis in one pass. Asking every alibi about every match would cost their product.

**An alibi excuses one place, or none.** An ambiguous alibi excuses none of its places, and a snippet with several matches and no occurrence excuses none of them, so a reason is never stretched over places it wasn't written for, as #7 decided. The matches it leaves are reported as unexcused, beside the alibi's failure.

**A file is indexed only when some alibi is for it.** `CheckedFiles` builds a file's index the first time it checks an alibi for that file, so an alibi file with no alibis reads each file as it did before alibis existed.

## Traps

- **A snippet's lines match only whole lines.** `y` doesn't occur in a file whose line is `y # TODO`; copy the line whole.
- **A match that starts in a snippet and ends after it isn't in the snippet.** An alibi for a pattern that spans lines needs a snippet that covers the match's last line too.
- **An occurrence counts the matches in the snippet, not on one line.** When a snippet's context lines hold matches too, they count.
- **Two alibis can each occur once and still excuse the same match,** when one snippet's lines overlap the other's. The verdict fails on that match, saying it has two alibis, and on neither alibi.
- **`Verdict` counts a match's alibis with `Array#tally`,** which compares matches by identity, since `Match` defines no `eql?` or `hash`. Two matches with the same text on one line are two matches; defining equality on `Match` by value would merge them.
- **This project's alibi files contain what they ban,** and so do the samples that test them. `bundle exec rake` runs `exe/alibi` over the alibi files in `.config/alibi/`, whose globs match only Ruby, RBS, and the files Bundler, Rake, and Steep read. The alibi files themselves are KDL, and each sample is a `.txt` file under `test/fixtures/`, so the check never reads them. `test/alibi_files_test.rb` reads the samples for each alibi file: a path its glob has to match, the forms its pattern has to find, and lines it has to leave alone. A new alibi file there needs a folder of samples too, or that test fails. Markdown is left out of the globs, since its prose names the very forms they ban.
- **`.` doesn't match a line break** unless the pattern starts with `(?m)`, and `^` and `$` match at every line, as Ruby has them.
- **`ProjectFile#matches` reads `Regexp.last_match` inside `to_enum(:scan, regexp)`,** which gives each match's position without a hand-written loop that has to step past empty matches. It takes the byte offset from `MatchData#byteoffset`, and `Lines` finds the line by a binary search in the byte offsets of the line starts, which it lists once. Counting line breaks from the start of the text for each match took time in proportion to the matches times the length of the file, which a file of many short lines made slow enough to look like a hang.
- **Paths in the output start at the project root,** not the folder where Alibi runs. A bare `alibi`, on the other hand, looks for `.config/alibi/` in the folder where it runs, not at the project root.
- **On Windows, git checks a symlink out as a plain file** when `core.symlinks` is false, so Alibi reads it there as a file whose text is the path of its target.
- **A file's text reaches the terminal.** `Escaped` shows every control character but a tab as the escapes of its bytes, C1 characters such as U+009B included, and a byte that isn't UTF-8 the same way. So it does the bidirectional overrides and isolates (U+202A to U+202E, U+2066 to U+2069) and the line and paragraph separators (U+2028, U+2029), which would let a project file make a match's line read differently from what it holds. `Report` and the errors `CommandLine` writes use it, so a project file, a path, or an alibi file can't move the cursor, set the terminal's title, reorder or break a line, or crash Alibi with an invalid string.

## What the check doesn't do

- **Read alibis.** An `alibi` node, with its snippet, reason, and occurrence, is an error until #38 settles its format and #11 what Alibi checks in a reason; until then, an alibi file passes only while its pattern matches nothing, and only tests reach the engine in [How an alibi finds its match](#how-an-alibi-finds-its-match).
- **Check a reason.** An alibi holds its reason as a string and checks nothing in it.
- **Ignore whitespace inside or at the end of a line,** or match a snippet against part of a line.
- **Say every place of an ambiguous snippet.** Its message gives the first two, which is enough to show that the snippet needs more lines.
- **Tell a path the glob doesn't match from a snippet that occurs nowhere.** Both make the alibi stale, with one message, since the same two remedies fix both.
- **Look further for alibi files.** A bare `alibi` reads only `*.kdl` files directly in `.config/alibi/`, with no folders below it and no search upward.
- **Take more than one glob or pattern in an alibi file,** or flags for the pattern outside the pattern itself.
- **Read a file outside the project root,** an ignored file, a file inside a submodule, or a file through a symlink.
- **Print color, or any format but lines of text.**
