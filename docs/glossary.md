# Glossary

The words Alibi's code, documentation, and issues use, with the meaning each has here.

| Word | Meaning | Avoid |
| --- | --- | --- |
| **match** | What an alibi file's pattern finds in the files the alibi file applies to. | hit |
| **alibi** | One item in an alibi file: a snippet that identifies one match, and the reason the rule can't hold there. It excuses that match and no other. | entry, approval, exception, allow |
| **alibi file** | A KDL file, named on the command line, that lists the files it applies to, a pattern, and its alibis. | ledger, exceptions file, allow-list, baseline (a baseline lists existing violations to tolerate, with nothing in the source marking them) |
| **snippet** | Lines copied from a file, written as a KDL multi-line raw string, that occur exactly once in that file and contain exactly one match of the alibi file's pattern. | excerpt |
| **reason** | The text in an alibi that says why the rule can't hold at that place, written for a reader who wasn't there when it was added. | justification, comment |
| **check** | One thing a linter, type checker, or compiler verifies about code, such as a Clippy lint, a RuboCop cop, a clang-tidy check, or Steep's type checking of a call. | lint, cop, rule (each is one tool's word) |
| **suppression** | The most common thing a pattern matches: code with which someone switches a check off at one place, written in the checking tool's syntax, such as `#[allow(clippy::needless_pass_by_value)]`, `# rubocop:disable Metrics/AbcSize`, `@ts-ignore`, or `// NOLINT`, or a construct with the same effect, such as RBS's `untyped`. | exception (in most languages it means a thrown error), ignore, directive |
| **whoever answers for the code** | The person or agent responsible for the code an alibi file covers: a maintainer, a reviewer, an orchestrating agent, or an auditor. | owner, team |
| **earlier version** | One of the approved-exceptions files, with the check that read it, kept in projects such as setdef/Tokra and setdef/Lota before Alibi. | predecessor |
