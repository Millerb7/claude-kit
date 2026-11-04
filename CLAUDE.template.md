# <PROJECT NAME>

<Give one or two sentences: what the project is, who uses it, and its current stage.>

## Layout

```
<path/>        <what lives here>
<path/>        <what lives here>
```

<List the one or two core files, so their locations are known without searching.>

## Context boundaries

**Exclude from search and direct reads:** <node_modules/, dist/, build/, .next/,
bin/, obj/, vendor/, packages/, *.lock, generated clients, migration history,
large fixtures>

These trees are generated, vendored, or both. Broad scans waste context and return noise. When checking a dependency API, open the single required file by exact path.

**Fetch just the required lines.** Prefer `sed -n '120,180p' file` or a contextual grep over loading the whole file. Read text remains in context and is re-sent on each later turn.

## Verification

<Name what proves a change works here. Keep it specific and runnable.>

```
<build command>
<test command>
```

A clean build is not a passing test. Report what actually ran; do not call a change working because compilation succeeded.

## Conventions

- <state a rule that is not obvious from reading the code>
- <state a naming or layout rule a newcomer would get wrong>
- <state the thing that has bitten someone before>

## Working agreement

- Apply only the requested change. Record other observations without fixing them in the same pass.
- If a request can be read in two ways that lead to different work, ask before building.
- Only make a commit, push, or PR when explicitly told to.
- Keep answers as short as the question requires. Output costs about five times input, and thinking bills as output, so restating the question has a real price. Drop preamble and do not summarize completed work unless asked.
- <state anything the branch protections or review process require>
