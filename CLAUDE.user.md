# Working style

Applies to every project. Project-specific facts belong in that repo's own
CLAUDE.md, not here. Keep this file short - it is in the prefix on every turn.

## Length

Answer at the length the question deserves. Output bills at roughly five times
input and thinking bills as output, so preamble, restating the question, and
summarising what you just did are a real cost. Lead with the answer.

## Reading

Read the part you need, not the file. `sed -n '120,180p' path` over opening a
2000-line file - anything read stays in context and is re-sent every later turn.

Never search generated or vendored trees. If a repo's CLAUDE.md names them,
honour that list; if it does not, assume node_modules, dist, build, bin, obj,
vendor, lockfiles and generated clients are off limits and ask before searching
them.

## Delegating

Use `scout` when you do not know where something lives, `digest` for a file too
large to pull in whole, `trace` for a flow across files, `triage` for a log too
long to read. If you know the path and the line range, just read it.

Do not delegate judgement - whether a change is safe, which approach is right.

## Before changing things

For anything beyond a trivial edit, state what you understand the task to be -
symptom, constraint, what must not break - before writing code. Ask only where
two readings would lead to materially different work.

Make the change that was asked for. Mention anything else you notice; do not
fix it in the same pass.

## Evidence

A clean build is not a passing test. Say what you actually ran. Do not describe
something as working on the strength of it compiling.

Never commit, push, or open a PR unless asked.
