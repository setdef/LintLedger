# Glossary

The words Alibi's code, documentation, and issues use, with the meaning each has here.

| Word | Meaning | Avoid |
| --- | --- | --- |
| **match** | What an alibi file's pattern finds in the files the alibi file applies to. | hit |
| **alibi** | One item in an alibi file: a snippet that identifies one match, and the reason that match is necessary at its place. It excuses that match and no other. | entry, approval, exception, allow |
| **alibi file** | A KDL file, named on the command line, that lists the files it applies to, a pattern, and its alibis. | ledger, exceptions file, allow-list, baseline (a baseline lists existing violations to tolerate, with nothing in the source marking them) |
| **glob** | An alibi file's `files` value: a pattern of paths, from the project root, that matches the files the alibi file applies to. | file pattern (a pattern is the regexp) |
| **pattern** | An alibi file's `pattern` value: a Ruby regular expression that Alibi runs over the text of each file the glob matches. It may ban anything, not only a suppression. | rule, ban, regex |
| **project root** | The top of the git working tree that holds an alibi file. Every path in a glob, and in Alibi's output, starts there. | repository root, base folder |
| **project file** | A file in the project that git tracks, or would track: tracked, or untracked and not ignored. Alibi reads only project files, and only those the glob matches. | source file (a project file may hold any text) |
| **verdict** | What Alibi concludes about one alibi file: it passes or it fails. On an error, such as an alibi file that isn't valid, Alibi reaches no verdict on that file. | result, status, outcome |
| **snippet** | Lines copied from a file, written as a KDL multi-line raw string, that occur exactly once in that file and contain exactly one match of the alibi file's pattern, or several that the alibi's occurrence picks from. Alibi ignores each line's leading whitespace when it compares a snippet with the file. | excerpt |
| **occurrence** | An alibi's optional `occurrence` value: a positive integer that says which of the matches in its snippet the alibi excuses, counting from 1, for matches that share a line. | index, nth |
| **reason** | The text in an alibi that says why that match is necessary at its place, written for a reader who wasn't there when it was added. | justification, comment |
| **unexcused match** | A match that no alibi excuses. Each one fails the verdict. | violation, offense |
| **stale alibi** | An alibi that matches nothing: its snippet occurs nowhere in its file, or the glob doesn't match its file. It fails the verdict until someone removes it or brings it up to date. | orphan, dead entry |
| **ambiguous alibi** | An alibi whose snippet occurs more than once in its file. It excuses none of those places, and fails the verdict until its snippet has enough lines to occur once. | duplicate |
| **check** | One thing a linter, type checker, or compiler verifies about code, such as a Clippy lint, a RuboCop cop, a clang-tidy check, or Steep's type checking of a call. | lint, cop, rule (each is one tool's word) |
| **suppression** | The most common thing a pattern matches: code with which someone switches a check off at one place, written in the checking tool's syntax, such as `#[allow(clippy::needless_pass_by_value)]`, `# rubocop:disable Metrics/AbcSize`, `@ts-ignore`, or `// NOLINT`, or a construct with the same effect, such as RBS's `untyped`. | exception (in most languages it means a thrown error), ignore, directive |
| **whoever answers for the code** | The person or agent responsible for the code an alibi file covers: a maintainer, a reviewer, an orchestrating agent, or an auditor. | owner, team |
| **earlier version** | One of the approved-exceptions files, with the check that read it, kept in projects such as setdef/Tokra and setdef/Lota before Alibi. | predecessor |
