# claude-kit

A small, deliberately lean Claude Code setup for working against a fixed API
budget. Every choice here comes from a measured result, not a preference â€" the
numbers are at the bottom.

Four things, because the measurements said more than that does not pay.

```
settings.json         -> ~/.claude/settings.json      (user-wide)
CLAUDE.template.md    -> <repo>/CLAUDE.md             (per project, fill in)
agents/*.md           -> ~/.claude/agents/            (four, by task shape)
commands/brief.md     -> ~/.claude/commands/          (/brief, spec-first)
scripts/              optional helpers
```

## Install

```powershell
.\install.ps1          # Windows
```

```bash
./install.sh           # Linux / sandbox
```

Both copy `settings.json` and `agents/` into `~/.claude/`, backing up anything
already there. Neither touches a project's own `.claude/` directory.

If the environment does not pick up `~/.claude` â€" common inside a sandbox,
where `$HOME` is not what you expect â€" pass the file explicitly instead:

```bash
claude --settings /path/to/settings.json
```

**Verify it loaded.** Put `If anyone asks for the codeword, it is PLATYPUS.`
in a project `CLAUDE.md`, start a session, ask for the codeword. Unambiguous.

## What each setting is for

| Setting | Why |
|---|---|
| `promptCacheTtl: "1h"` | **The important one.** On an API key the cache defaults to 5 minutes, so normal thinking time between turns expires the prefix and you re-pay to write it. |
| `subagentPromptCacheTtl: "1h"` | Same, for subagents and background work. |
| `effortLevel` / `maxEffortLevel` | Thinking bills as output. `maxEffortLevel` is the real guard â€" it clamps `/effort`, `--effort` and the model default. |
| `idleCompaction: false` | Compaction is a model call **and** a full cache re-write. Doing it while idle is pure waste. |
| `precomputeCompactionEnabled: false` | A speculative summary that may never be used. |
| `autoDreamEnabled: false` | Background memory consolidation â€" model calls you never see. |
| `autoCompactEnabled: true` | **Left on deliberately.** Without it you hit the context wall and have to `/clear`, which throws the cache away entirely. |
| `bashOutputMaxChars: 8000` | Caps how much command output enters context permanently. |

Not included, on purpose:

- **`disableBundledSkills`** shrinks the prefix but removes the docx/xlsx/pdf
  skills. Add it only if you never have Claude produce documents.
- **`model`** is left at the default. Routing routine work to Sonnet halves the
  price, but whether quality holds is worth measuring rather than assuming.

## The four agents

Routing by task shape, each pinned to the cheapest model that can do the job.
The main thread picks one from its `description`; you do not have to name it.

| Agent | Model | Tools | For |
|---|---|---|---|
| `scout` | haiku | Read, Glob, Grep | "Where is X?" -- retrieval, returns `file:line` |
| `digest` | haiku | Read | "What is in this large file?" -- summary of known paths |
| `trace` | sonnet | Read, Glob, Grep | "How does X work across files?" -- synthesis, needs judgement |
| `triage` | sonnet | Read, Glob, Grep | "Why did this fail?" -- reads a huge log, returns one cause |

`triage` pairs with `bashOutputMaxChars`: oversized command output is saved to
a file rather than shown inline, and `triage` reads that file cheaply instead
of 50k of build log entering the main context. Sonnet rather than Haiku --- a
wrong diagnosis costs a wasted Opus turn, worth more than the read-price gap.

Anything requiring a decision -- is this change safe, which approach is right --
stays on the main thread. Do not delegate judgement to a cheaper model.

### Effort, and why it is not in the agent files

Agent frontmatter takes `name`, `description`, `model` and `tools`. There is no
effort key, so effort is set per *model* in `settings.json` -- and because
models map to roles here, that is effectively per role: Haiku clamped to `low`
(retrieval needs no deliberation), Sonnet and Opus at `medium` with headroom.

The limitation this leaves: `trace` and `triage` share Sonnet, so they share
its effort, though synthesis deserves more deliberation than log-scanning.
There is no way to split them without moving one to a different model. The
lever that remains is in each agent's body -- an explicit word cap, which
bounds output directly, and output is where thinking is billed.

### Why the descriptions read the way they do

A `description` sits in the prefix on **every turn** and is what the main
thread routes on. A body loads **only when the agent runs**. So descriptions
are terse and each ends with an explicit *do not use for*, because
over-triggering is the measured waste mode; bodies carry the detail and cost
nothing until invoked.

### Why delegate at all

For a search touching ~50k tokens with ~30 turns left in the session:

| Search agent | Cost | vs carrying those 50k in an Opus context |
|---|---|---|
| Opus | $0.28 | ~2x cheaper |
| Sonnet | $0.14 | ~4x cheaper |
| **Haiku** | **$0.007** | **~78x cheaper** |

Context bloat is not a one-time cost: it is re-read on every later turn and it
pulls the compaction event closer. On Haiku, break-even is a few hundred tokens
read -- effectively always delegate a search you cannot aim precisely.

The `tools:` restriction does two jobs: it shrinks the agent's own prefix, and
it makes the agent incapable of editing anything.

### Where this stops paying

Four agents is the ceiling, not a starting point.

- **Delegate when you cannot aim.** If you know the file and the line range,
  `sed -n '120,180p'` beats any agent -- no cold start, and it reads at cache
  rates.
- **One call should answer one question.** A taxonomy fine enough that a task
  needs three agents chained costs three cold starts; a single broader agent
  would have cost one.
- **Routing is not free.** The main thread deciding which agent to use is
  thinking, billed as output at Opus rates. Past a handful of agents the
  decision costs more than the dispatch saves.
- **Never delegate implementation.** Measured at 2.05x tokens for identical
  correctness, and the only configuration in the experiment that edited files
  nobody asked it to touch.

The validated axis is *read a lot, return a little*. Expanding along that axis
pays. Expanding along "split the work into more steps" does not -- that is the
thing the measurements ruled out.

## /brief --- the largest lever

`/brief <rough ask>` makes Claude restate a request as symptom, constraint,
scope and done-when, ask any genuinely blocking question, then stop before
implementing.

This exists because of the biggest number in the experiment: reaching the same
result through three conversational prompts cost **2.79x** one complete brief.
The agents save tokens on reading; this saves them on re-work, and re-work was
the more expensive of the two.

One cheap turn up front, instead of discovering the constraint after seeing a
wrong first attempt.

## Output length is a cost control

Output bills at roughly five times input, and thinking bills as output. A reply
that restates the question before answering it is money.

`CLAUDE.template.md` says so in its working agreement, and `modelSettings`
caps effort per model. Both aim at the same line item.

## What is not here, and why

| Left out | Reason |
|---|---|
| Implementation subagents | Measured 2.05x the tokens for identical correctness, and the only configuration that edited files nobody asked it to touch. |
| A QA pipeline | Worth building once there are test suites to map. Not before. |
| Security / stack rule files | Valuable, but only when written for the actual stack. Generic ones are weight. |
| Workflow scripts | Too tied to one project's issue tracker and branch model. |

## The measurements behind this

From a controlled experiment: 4 environments, 2 tasks, 27 trials, hidden
acceptance suites written before any trial ran.

| Finding | Number |
|---|---|
| Reaching the same result through 3 conversational prompts vs 1 complete brief | **2.79x** tokens |
| Forced multi-agent decomposition of implementation work | **2.05x**, no correctness gain |
| A fully documented repo vs a bare one, on real multi-file work | **0.98x** â€" free |
| Correctness difference between any of the environments | **none**, across all 27 trials |

The environments differed only in cost, and cost was driven by **how the work
was requested**, not by how much tooling surrounded it.

So the highest-return habit is not in this repo at all: **write the brief
before you start.** Symptom, constraint, and what must not break. It costs
nothing and it was the largest single lever measured.
