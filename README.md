# claude-kit

A small, deliberately lean Claude Code setup for working against a fixed API
budget. Every choice here comes from a measured result, not a preference — the
numbers are at the bottom.

Four things, because the measurements said more than that does not pay.

```
settings.json         -> ~/.claude/settings.json      (user-wide)
CLAUDE.template.md    -> <repo>/CLAUDE.md             (per project, fill in)
agents/scout.md       -> ~/.claude/agents/scout.md     (search, on Haiku)
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

If the environment does not pick up `~/.claude` — common inside a sandbox,
where `$HOME` is not what you expect — pass the file explicitly instead:

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
| `effortLevel` / `maxEffortLevel` | Thinking bills as output. `maxEffortLevel` is the real guard — it clamps `/effort`, `--effort` and the model default. |
| `idleCompaction: false` | Compaction is a model call **and** a full cache re-write. Doing it while idle is pure waste. |
| `precomputeCompactionEnabled: false` | A speculative summary that may never be used. |
| `autoDreamEnabled: false` | Background memory consolidation — model calls you never see. |
| `autoCompactEnabled: true` | **Left on deliberately.** Without it you hit the context wall and have to `/clear`, which throws the cache away entirely. |
| `bashOutputMaxChars: 8000` | Caps how much command output enters context permanently. |

Not included, on purpose:

- **`disableBundledSkills`** shrinks the prefix but removes the docx/xlsx/pdf
  skills. Add it only if you never have Claude produce documents.
- **`model`** is left at the default. Routing routine work to Sonnet halves the
  price, but whether quality holds is worth measuring rather than assuming.

## The scout agent

One agent, pinned to Haiku, read-only, forbidden from pasting code.

Delegate a search when you do **not** know where something lives. Read the file
yourself when you do — a targeted `sed -n '120,180p'` beats any agent.

The economics, for a search touching ~50k tokens with ~30 turns left in the
session:

| Search agent | Cost | vs carrying those 50k in an Opus context |
|---|---|---|
| Opus | $0.28 | ~2x cheaper |
| Sonnet | $0.14 | ~4x cheaper |
| **Haiku** | **$0.007** | **~78x cheaper** |

Context bloat is not a one-time cost: it is re-read on every later turn and it
pulls the compaction event closer. A Haiku search pays for itself almost
immediately — break-even is a few hundred tokens read.

The `tools:` restriction does two jobs: it shrinks the agent's own prefix, and
it makes the agent incapable of editing anything.

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
| A fully documented repo vs a bare one, on real multi-file work | **0.98x** — free |
| Correctness difference between any of the environments | **none**, across all 27 trials |

The environments differed only in cost, and cost was driven by **how the work
was requested**, not by how much tooling surrounded it.

So the highest-return habit is not in this repo at all: **write the brief
before you start.** Symptom, constraint, and what must not break. It costs
nothing and it was the largest single lever measured.
