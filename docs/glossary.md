# Glossary

The words Alibi's code, documentation, and issues use, with the meaning each has here.

| Word | Meaning | Avoid |
| --- | --- | --- |
| **check** | One thing a linter, type checker, or compiler verifies about code, such as a Clippy lint, a RuboCop cop, a clang-tidy check, or Steep's type checking of a call. | lint, cop, rule (each is one tool's word) |
| **suppression** | Code with which someone switches a check off at one place, written in the checking tool's syntax, such as `#[allow(clippy::needless_pass_by_value)]`, `# rubocop:disable Metrics/AbcSize`, `@ts-ignore`, or `// NOLINT`, or a construct with the same effect, such as RBS's `untyped`. | exception (in most languages it means a thrown error), ignore, directive |
| **ledger** | A file of entries, written in Alibi's Ruby DSL, that people review. | exceptions file, allow-list, baseline (a baseline lists existing violations to tolerate, with nothing in the source marking them) |
| **entry** | One item in a ledger: the suppression or other thing it records, and its reason. | approval, exception, allow |
| **reason** | The text in an entry that says why the check is wrong at that place, written for a reader who wasn't there when it was added. | justification, comment |
| **whoever answers for the code** | The person or agent responsible for the code a ledger covers: a maintainer, a reviewer, an orchestrating agent, or an auditor. | owner, team |
| **plugin** | Code that gives Alibi one linter's or language's knowledge, such as what its suppressions look like and where they are found. Alibi has no built-in knowledge of any linter. | detector, adapter |
| **earlier version** | One of the approved-exceptions files, with the check that read it, kept in projects such as setdef/Tokra and setdef/Lota before Alibi. None of them used the word *ledger*. | ledger, predecessor |
