# Working style

This is the global style. It applies to every project. Put project facts in that repo's CLAUDE.md, not here. Keep this file short because it enters the prompt prefix on each turn.

## Length

Match answer length to the question. Output bills at ~5x input, and thinking bills as output. Skip preamble, restating the question, and needless summary. Start with the answer.

## Reading

Read only the needed line range. Do not open a large file just to find a few lines. Everything read stays in context and is resent on later turns.

Never search generated or vendored trees. If the repo CLAUDE.md lists its own, follow that list. If it does not, treat node_modules, dist, build, bin, obj, vendor, lockfiles, and generated clients as off limits. Ask before searching any of them.

## Delegating

Use scout when the path is unknown. Use digest when a known file is too large to read whole. Use trace for a flow across several files. Use triage for a log too long to inspect inline. If the path and line range are known, read it directly. Never delegate judgement.

## Before changing things

For nontrivial edits, state the symptom, the constraint, and what must not break before writing code. Ask only where two readings would lead to materially different work.

Make only the requested change. Mention other issues found, but do not fix them in the same pass.

## Evidence

A clean build is not a passing test. Report the command actually run. Do not claim behavior from compilation alone.

Never commit, push, or open a PR unless asked.
