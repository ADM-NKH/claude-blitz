<div align="center">

# ⚡ Blitz

**Feed it goals; it ships increments while you're away.**
A continuously-firing background work runner for Claude Code. Queue tasks, track long-term goals, and enable per-project audit rotations.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.2.0-brightgreen.svg)](CHANGELOG.md)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)](#install)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-skill-orange.svg)](https://claude.ai/code)

</div>

---

## The problem

Claude Max is flat-rate. If you don't use your quota, it expires at reset.
The natural fix isn't to *burn* tokens — it's to keep a list of real work
and run it through before the window closes.

That's what Blitz does.

## What it does

- 📝 **Queue tasks anytime.** `/blitz add Refactor auth.js` adds to a personal backlog.
- ⚡ **Run them in parallel.** `/blitz` spawns N agents simultaneously, each on a different task.
- 💾 **Persists every output.** Each agent writes a markdown file to `~/blitz/runs/<timestamp>/` — nothing lost.
- 🤖 **Optional auto-fire.** Configure once and Blitz runs your backlog automatically before each reset.
- 🛑 **Always reversible.** `/blitz off` disables auto-fire. `/blitz skip` skips the next one.

> **Honest framing:** Parallelism is for *throughput*, not for inflating your quota.
> Five tasks finished in the time of one — that's the win. Empty backlog → no run.

---

## Install

**Recommended — works on every supported AI harness:**

```bash
npx skills add ADM-NKH/claude-blitz
```

Auto-detects your harness (Claude Code, Cursor, Codex, Gemini, …) and writes the skill files to the right location. Powered by [`vercel-labs/skills`](https://github.com/vercel-labs/skills).

<details>
<summary>Other install options</summary>

**Mac / Linux:**

```bash
curl -fsSL https://raw.githubusercontent.com/ADM-NKH/claude-blitz/main/install.sh | bash
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/ADM-NKH/claude-blitz/main/install.ps1 | iex
```

**Manual (any OS):**

```bash
git clone https://github.com/ADM-NKH/claude-blitz.git ~/.claude/skills/blitz
```

</details>

Then, in your AI harness:

```text
/blitz setup                              # one-time config
/blitz add Refactor auth.js               # queue work
/blitz add Generate tests for billing
/blitz                                    # run the backlog now
```

---

## Demo

```
$ /blitz

╔══════════════════════════════════════════════════════╗
║                   ⚡ BLITZ — RUN PLAN                 ║
╠══════════════════════════════════════════════════════╣
║  Pulling 3 of 7 backlog items                        ║
║  Output: ~/blitz/runs/2026-05-03_0830-manual/        ║
╚══════════════════════════════════════════════════════╝

  #1  Refactor auth.js for clarity            [myapp]
  #2  Generate tests for billing module       [myapp]
  #3  Write API docs for /v2 endpoints        [api-svc]

Launch 3 parallel agents? (go / adjust / cancel)
> go

[3 agents spawn simultaneously, each writes its full output to disk]

╔══════════════════════════════════════════════════════╗
║                  ⚡ BLITZ COMPLETE                    ║
╠══════════════════════════════════════════════════════╣
║  Tasks done:  3                                      ║
║  Output:      ~/blitz/runs/2026-05-03_0830-manual/   ║
║  Backlog:     4 items remaining                      ║
╚══════════════════════════════════════════════════════╝

Open the summary: ~/blitz/runs/2026-05-03_0830-manual/_summary.md
```

---

## Commands

| Command | Description |
| --- | --- |
| `/blitz` | Run the backlog now — pulls top N, spawns parallel agents, persists output |
| `/blitz add <task>` | Add to backlog (uses cwd as project; override with `--project <path>`) |
| `/blitz list` | Show the backlog |
| `/blitz remove <id>` | Remove an item |
| `/blitz clear` | Clear the entire backlog (with confirmation) |
| `/blitz setup` | Configure reset schedule, output dir, and optional auto-fire |
| `/blitz auto` | Unattended run (called by the scheduled job — don't run manually) |
| `/blitz off` / `on` | Disable / re-enable auto-fire |
| `/blitz skip` | Skip the next scheduled fire |

### Goals (long-term)

- `/blitz goal add "Ship pluginproof MVP"` — register a goal in the current project
- `/blitz goal list` — show goals with branch and increment count
- `/blitz goal review <id>` — show the goal branch's diff vs main and plan status
- `/blitz goal log <id>` — show what blitz has shipped for this goal so far
- `/blitz goal autopush <id> on|off` — opt the goal into pushing increments to origin

### Audits (per-project maintenance)

- `/blitz audit enable <project>` — add a project to the audit rotation
- `/blitz audit list` — show enabled audits and last-swept dates
- `/blitz audit run <project>` — run the next audit in rotation right now
- `/blitz audit disable <project>` — remove an audit

---

## How it fires

Blitz runs on a hybrid cadence + per-project idle-gate model. A single OS scheduled job (`Blitz-Cadence`) wakes every `cadenceHours` (default 3h) and checks each backlog item. Before touching a project, blitz inspects its git state: if you've committed within the last `idleMinutes` (default 30) or the working tree is dirty, that item is deferred to the next fire. Optional blackout windows let you suppress firing during specific hours (e.g. weekday work hours). Each fire pulls a tier of items — goals first, then tasks, then audits — capped per `firing.caps`. Goals decompose into a durable `plan.md`; the first fire writes the plan, subsequent fires implement one increment each on a long-lived `blitz/goal-<id>` branch. Audits produce read-only reports and auto-promote one new finding per fire to the backlog.

> **Empty backlog + nothing enabled → silent exit.** Auto mode never invents work.

---

## Output structure

Every run creates a timestamped folder under `~/blitz/runs/`:

```
~/blitz/
├── blitz.log                            # auto-fire history
└── runs/
    └── 2026-05-03_0830-weekly/
        ├── _summary.md                  # start here
        ├── 1-refactor-auth.md           # agent 1's full output
        ├── 2-add-tests.md               # agent 2's full output
        └── 3-update-docs.md
```

---

## Uninstall

**Recommended:**

```bash
npx skills remove blitz
```

<details>
<summary>Other uninstall options</summary>

**Mac / Linux:**

```bash
curl -fsSL https://raw.githubusercontent.com/ADM-NKH/claude-blitz/main/uninstall.sh | bash
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/ADM-NKH/claude-blitz/main/uninstall.ps1 | iex
```

</details>

The uninstaller removes the skill and any scheduled jobs, but **preserves** your config and run history. Delete those manually if you want a clean slate.

---

## FAQ

**Does this give me more Claude tokens?**
No. Your quota is fixed. Blitz just helps you *use* what you have on real work instead of letting it expire idle.

**Will Anthropic's fair-use policy flag me?**
Blitz only runs work you queue yourself. Empty backlog, no run. There's no token-pumping or filler generation. You're using your subscription for what it's for.

**What if `claude -p` doesn't work in a Task Scheduler context on my Windows machine?**
The setup wizard runs an immediate auth test and tells you clearly if it doesn't work. The manual `/blitz` mode keeps working either way.

**Can I edit the backlog in my editor instead of using commands?**
Yes — it lives at `~/.claude/blitz.json`. Just keep the schema valid.

**Where does Blitz keep its data?**

- Config + backlog: `~/.claude/blitz.json`
- Run output: `~/blitz/runs/<timestamp>/`
- Auto-fire log: `~/blitz/blitz.log`

---

## Roadmap

- [ ] Desktop notifications when an auto-fire completes
- [ ] Web UI for backlog management
- [ ] Auto-detect reset times from Claude UI (Playwright)
- [ ] Better Mac/Linux end-to-end testing
- [ ] Per-task model selection (Haiku/Sonnet/Opus)

---

## Contributing

PRs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) — Adam (ADM-NKH)

---

<div align="center">

*For people who keep finding 30 unused minutes left in the week.*

</div>
