# <PROJECT NAME>

<One or two sentences: what this is, who uses it, what stage it is at.>

## Layout

```
<path/>        <what lives here>
<path/>        <what lives here>
```

<Name the one or two files that are the heart of the system, so finding them
does not need a search.>

## Context boundaries

**Never search or read:** <node_modules/, dist/, build/, .next/, bin/, obj/,
vendor/, packages/, *.lock, generated clients, migration history, large
fixtures>

These are large, generated, or both. An unbounded search across them burns a
context window and returns noise. To learn an API from a dependency, open the
one file needed, by exact path.

**Read only the part you need.** Prefer `sed -n '120,180p' file` or a grep with
context over reading a whole file. Anything read stays in context and is
re-sent on every later turn.

## Verification

<What proves a change works here. Specific and runnable.>

```
<build command>
<test command>
```

A clean build is not a passing test. State what was actually run; do not
describe a change as working on the strength of it compiling.

## Conventions

- <a rule that is not obvious from reading the code>
- <a naming or layout rule a newcomer would get wrong>
- <the thing that has bitten someone before>

## Working agreement

- Make the change that was asked for. Note anything else you notice; do not
  fix it in the same pass.
- When a request is ambiguous and the readings lead to different work, ask
  before building.
- Never commit, push, or open a PR unless asked.
- Answer at the length the question deserves. Output bills at roughly five
  times input, and thinking bills as output, so a paragraph that restates the
  question costs real money. Skip preamble, skip summarising what you just did
  unless asked.
- <anything the branch protections or review process require>
