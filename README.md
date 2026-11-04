# claude-kit

A small, intentionally lean Claude Code setup for a fixed API budget. Each choice stays because measurement showed a saving, not because it is preferred. The numbers are at the end.

Four things remain, because the measurements showed that adding more does not pay.

```
settings.json         -> ~/.claude/settings.json      (user-wide)
CLAUDE.template.md    -> <repo>/CLAUDE.md             (per project, fill in)
CLAUDE.user.md        -> ~/.claude/CLAUDE.md          (working style, global)
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

`install.sh` and `install.ps1` copy `settings.json`, `CLAUDE.user.md` (landing as `~/.claude/CLAUDE.md`), `agents/*` and `commands/*` into `$HOME/.claude`. They honour a `CLAUDE_HOME` override, take a timestamped backup (`.bak-<stamp>`) of anything they would overwrite, and print each destination plus the resolved `HOME`. They do not install `CLAUDE.template.md` (it is per-repo) or anything under `scripts/`, and they leave a project's own `.claude/` directory alone.

If the environment does not pick up `~/.claude`, as can happen in a sandbox where `$HOME` is not what you expect, pass the file explicitly instead:

```bash
claude --settings /path/to/settings.json
```

**Verify it loaded.** Put `If anyone asks for the codeword, it is PLATYPUS.`
in a project `CLAUDE.md`, start a session, ask for the codeword. Unambiguous.

## What each setting is for

| Setting | Why |
|---|---|
| `promptCacheTtl: "1h"` | **Core cost control.** On an API key the cache starts at 5 minutes, so ordinary pauses age the prefix and the next turn writes it again at full price. |
| `subagentPromptCacheTtl: "1h"` | Applies the same cache window to subagents and background work. |
| `effortLevel` / `maxEffortLevel` | Thinking tokens bill as output tokens. `maxEffortLevel` enforces the ceiling across `/effort`, `--effort`, and the model default. |
| `idleCompaction: false` | Each compaction spends a model call plus a full cache write. Running it while idle uses budget with no saving. |
| `precomputeCompactionEnabled: false` | Stops an anticipated compaction summary that may never be consumed. |
| `autoDreamEnabled: false` | Suppresses background memory consolidation, which would run as hidden model calls. |
| `autoCompactEnabled: true` | **Kept true by design.** Turning it off can fill context and force `/clear`, discarding the cache, a worse outcome than compacting. |
| `bashOutputMaxChars: 8000` | Sets the maximum amount of command output retained in context. |

Left out, deliberately:

- **`disableBundledSkills`** trims the prefix but costs the docx/xlsx/pdf document skills. Enable it only when Claude will not build documents.
- **`model`** is not pinned. Sending routine work to Sonnet halves cost, but the quality tradeoff should be validated before routing.

## The four agents

Agents are chosen by task shape. Each agent is bound to the least expensive model that can cover that shape. Selection is driven by the agent `description`, so the user does not choose the agent by name.

| Agent | Model | Tools | For |
|---|---|---|---|
| `scout` | haiku | Read, Glob, Grep | unknown-path lookup, answer is `file:line` |
| `digest` | haiku | Read | summarize files already located |
| `trace` | sonnet | Read, Glob, Grep | explain a behavior that spans files |
| `triage` | sonnet | Read, Glob, Grep | reduce a huge log to one likely cause |

Oversized command output is written to a file when `bashOutputMaxChars` trips, and `triage` consumes that file instead of letting 50k of build log enter the main context. The model is Sonnet, not Haiku: a false diagnosis can burn an Opus turn, and that burn is larger than the read-rate saving.

Every judgment call, such as whether a change is safe or which approach is correct, remains on the main thread. A cheaper model must not own the judgment.

### Effort, and why it is not in the agent files

Each agent file starts with four frontmatter fields: `name`, `description`, `model`, and `tools`. Effort is absent from that set, so `settings.json` sets it by *model*. In this kit, a model name doubles as a role label, so effort set by model also behaves as effort set by role: Haiku is fixed at `low` because lookups need little thought, while Sonnet and Opus hold `medium` and keep room to climb.

One consequence is that `trace` and `triage` both inherit the Sonnet effort setting, although tracing a flow wants more deliberation than scanning logs. A frontmatter-only change cannot break that tie; a model swap would be required. The remaining control lives in the body: a hard word limit sets a token ceiling and thereby limits the thinking charge, since thinking bills as output.

### Why the descriptions read the way they do

The `description` field is sent in the prefix on **every turn**, and the main thread uses it as the routing signal. The body enters context **only when that agent actually starts**. Because extra triggers are the measured source of waste, descriptions stay short and each names a *do not use for* case. The detailed rules wait in the body, so they create no cost until the agent is invoked.

### Why delegate at all

Take a search that would read ~50k tokens while ~30 turns remain in the session:

| Search agent | Cost | price compared with leaving those 50k in an Opus context |
|---|---|---|
| Opus | $0.28 | ~2x cheaper |
| Sonnet | $0.14 | ~4x cheaper |
| **Haiku** | **$0.007** | **~78x cheaper** |

That extra context is not a single expense. It is re-sent with each subsequent turn, and it advances the compaction event. For Haiku, the crossover appears after only a few hundred read tokens, which makes delegation the default for any search lacking a precise target.

The `tools:` line has two effects: it cuts the agent's prefix size and removes its ability to modify files.

### Where this stops paying

The count of four is an upper bound, not a minimum.

- **Dispatch a lookup only when the target is not already fixed.** With file and line range in hand, `sed -n '120,180p'` outperforms an agent, because it avoids a cold start and reads at cache rates.
- **One dispatch should close one question.** A taxonomy so fine that a task chains three agents pays three cold starts; one broader agent would have paid one.
- **Selection has a price.** The main thread's act of choosing is thinking, billed as output at Opus rates. Once the agent list grows beyond a small set, that choice outweighs the dispatch saving.
- **Never delegate implementation.** The measurement was 2.05x tokens for identical correctness, and it was the only experiment setup that edited files it was not asked to touch.

The axis that held up under measurement is *read a lot, return a little*. Capacity on that axis pays. Capacity aimed at "split the work into more steps" does not pay; the measurements ruled out that direction.

## Two CLAUDE.md files, on purpose

| File | Scope | Holds |
|---|---|---|
| `~/.claude/CLAUDE.md` | every project | *how you work* - length, reading, delegation, evidence |
| `<repo>/CLAUDE.md` | one project | *what this codebase is* - layout, boundaries, build, conventions |

Prefix load on every turn forces both to stay short. The global file is ~300 words and should not grow; content true of only one codebase belongs in that codebase's file.

An `agent` setting can point the main thread at a custom agent definition and apply its system prompt, tool restrictions and model. That is a stronger lever than a global CLAUDE.md. The docs do not state whether that system prompt replaces the Claude Code default or adds to it. Keep the global CLAUDE.md for now; it adds the same constraints and keeps default behavior intact.

## /brief --- the largest lever

`/brief <rough ask>` forces Claude to restate a rough ask as symptom, constraint, scope and done-when, asks only genuinely blocking questions, then stops before implementing.

It targets the largest measured number: three conversational prompts reaching one result cost **2.79x** one complete brief. Agents cut read tokens; this cuts re-work tokens, and re-work proved the larger cost.

It spends one cheap turn up front instead of finding the constraint after a wrong first attempt.

## Output length is a cost control

Because output costs about five times input and thinking is billed as output, any restated question adds cost.

`CLAUDE.template.md` makes that rule explicit in its working agreement, while `modelSettings` limits effort per model. The two controls hit the same spend item.

## What is not here, and why

| Left out | Reason |
|---|---|
| Implementation subagents | Measurement showed 2.05x more tokens for the same correctness, and this setup was the only one that modified files outside the request. |
| A QA pipeline | Build it after test suites exist to map. Before that it adds no value. |
| Security / stack rule files | They pay only when written for the stack in use. Generic rules add weight without signal. |
| Workflow scripts | Too bound to a single project issue tracker and branch model. |

## The measurements behind this

The figures below came from a controlled test: 4 environments, 2 tasks, 27 trials, and hidden acceptance suites built before trial one began.

| Finding | Number |
|---|---|
| Reaching the same result through 3 conversational prompts vs 1 complete brief | **2.79x** tokens |
| Forced multi-agent decomposition of implementation work | **2.05x**, with no gain in correctness |
| A fully documented repo vs a bare one, on real multi-file work | **0.98x**, free |
| Correctness difference between any of the environments | **none**, in all 27 trials |

The only split between the setups was cost. That cost tracked **how the work was requested**, not how much tooling stood around it.

**Write the brief before you start.** The highest-return habit lives with you, not in this repo. Name symptom, constraint, and what must not break. It costs nothing and was the largest single lever measured.
