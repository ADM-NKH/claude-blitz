---
name: blitz
description: A continuously-firing background work runner for Claude Code. Queue real tasks ("/blitz add"), track long-term goals ("/blitz goal add"), and enable per-project audit rotations ("/blitz audit enable"). Blitz fires on a configurable cadence with a per-project idle gate, decomposes goals into increments on a long-lived branch, and persists every fire's output to ~/blitz/runs/<timestamp>/. Includes commands to manage the backlog, goals, audits, schedules, and kill switches (off/on/skip).
---

# ⚡ Blitz — Pre-Reset Backlog Runner

A Claude Code skill for people on Claude Max plans. Queue tasks you've been meaning to get to during the week. Blitz runs them through parallel agents — on demand, or automatically right before your quota resets — and writes every agent's output to disk so you wake up to actual artifacts, not a closed terminal.

**Parallelism is for throughput, not quota multiplication.** Five agents finish five tasks in the time of one — that's the win.

---

## Step 0 — Route by Subcommand

Read the first word of arguments after `/blitz`:

| Subcommand | Action |
|---|---|
| `add` | Add a task to the backlog (M-ADD) |
| `list`, `ls` | Show the backlog (M-LIST) |
| `remove`, `rm` | Remove a backlog item by number (M-REMOVE) |
| `clear` | Clear all backlog (with confirmation) (M-CLEAR) |
| `goal add` / `goal list` / `goal review` / `goal log` / `goal remove` / `goal autopush` | Goal lifecycle (M-GOAL) |
| `audit enable` / `audit disable` / `audit list` / `audit run` | Audit lifecycle (M-AUDIT) |
| `setup` | Run the configuration wizard (M-SETUP) |
| `auto` | Unattended scheduled run (M-AUTO) |
| `off` | Disable auto-schedule firing (M-OFF) |
| `on` | Re-enable auto-schedule firing (M-ON) |
| `skip` | Skip the next scheduled auto-fire (M-SKIP) |
| empty / anything else | **Run the backlog now** (M-RUN) |

**Config path:** `~/.claude/blitz.json` (Windows: `C:\Users\<user>\.claude\blitz.json`)
**Output path:** `~/blitz/runs/<timestamp>/` (Windows: `C:\Users\<user>\blitz\runs\<timestamp>\`)

If `~/.claude/blitz.json` doesn't exist on any subcommand other than `setup`, create a minimal default with empty `backlog: []` so reads don't fail. Don't force setup on first run.

---

## M-ADD — Add a Task to the Backlog

Syntax: `/blitz add <task description>` (optional flag: `--project <path>`)

1. Parse the task description (everything after `add` minus any flags).
2. Determine project path:
   - If `--project <path>` provided, use it.
   - Otherwise, use the current Claude Code working directory.
3. Append to `backlog[]` in config:
   ```json
   { "id": <next>, "task": "<description>", "project": "<absolute path>", "added": "YYYY-MM-DD" }
   ```
4. Confirm:
   ```
   ✅ Added #[id] to backlog
      Task:    <description>
      Project: <project path>
      Backlog now has [N] item(s).
   ```

If the task description is empty, ask the user what they want to add.

---

## M-LIST — Show the Backlog

Display every backlog item with its id, task, project (shortened), and date added. Group by project if there are multiple. Show total count at top.

```
⚡ Blitz backlog — [N] items

  #1  Refactor auth.js for clarity              [myapp]    added 2026-04-29
  #2  Generate tests for billing module         [myapp]    added 2026-04-30
  #3  Write API docs for /v2 endpoints          [api-svc]  added 2026-05-01

Run /blitz to blitz through them.
```

If empty: `Backlog is empty. Add something with /blitz add <task>`.

---

## M-REMOVE — Remove an Item

Syntax: `/blitz remove <id>` (or `rm`).

Remove the item with that id from `backlog[]`. Confirm:
```
✅ Removed #[id]: <task>. Backlog now has [N] item(s).
```

If the id doesn't exist, list the current backlog and ask which to remove.

---

## M-CLEAR — Clear Everything

Confirm first: `Clear all [N] backlog items? (yes/no)`. Only proceed on explicit "yes". Then empty `backlog: []` and confirm.

---

## M-GOAL — Goal Lifecycle

Long-term goals are user-defined objectives that compound over many fires. Each goal has a durable plan (`~/blitz/goals/<id>/plan.md`) and a long-lived branch (`blitz/goal-<id>`). Goal items live in `backlog[]` with `kind: "goal"`.

### M-GOAL-ADD — Add a goal

Syntax: `/blitz goal add <description>` (optional flag: `--project <path>`)

1. Parse the description.
2. Determine project path: `--project` flag, else current cwd.
3. Append to `backlog[]`:

```json
{
  "id": <next>,
  "kind": "goal",
  "task": "<description>",
  "project": "<absolute path>",
  "added": "YYYY-MM-DD",
  "branch": "blitz/goal-<id>",
  "autoPush": false,
  "lastTouched": null,
  "incrementCount": 0
}
```

4. Confirm:

```text
✅ Added goal #[id] to backlog
   Goal:    <description>
   Project: <project path>
   Branch:  blitz/goal-<id> (will be created on first increment fire)
   Plan:    ~/blitz/goals/<id>/plan.md (will be written on first fire)
```

The plan is **not** written at queue time. The first fire on this goal writes it.

### M-GOAL-LIST — Show goals

Display every `kind: "goal"` item with id, description, project, branch, increment count, and last-touched date. If none, print: `No goals. Add one with /blitz goal add <description>.`

### M-GOAL-REVIEW — Review a goal's branch

Syntax: `/blitz goal review <id>`

1. Look up the goal item; load `branch` field.
2. In the goal's `project` directory, run:

```bash
git log <branch> ^main --oneline
git diff main..<branch> --stat
```

3. Print plan.md status: count of `[x]`, `[ ]`, and `[~]` items.
4. End with a hint: `Merge with: git checkout main && git merge <branch>`.

If the branch doesn't exist, print: `No commits yet on this goal.`

### M-GOAL-LOG — Show increment history

Syntax: `/blitz goal log <id>`

Read every result file in `~/blitz/runs/*/goal-<id>-*.md` (sorted by timestamp), print the top-level heading and the first paragraph of each.

### M-GOAL-REMOVE — Remove a goal

Syntax: `/blitz goal remove <id>`

Remove the item from `backlog[]`. **Do not** delete the branch or plan.md. Print:

```text
✅ Removed goal #[id]: <description>
   The branch blitz/goal-<id> and plan.md were left in place.
   Clean up manually: git branch -D blitz/goal-<id> && rm -rf ~/blitz/goals/<id>
```

### M-GOAL-AUTOPUSH — Toggle autopush

Syntax: `/blitz goal autopush <id> on|off`

Set `autoPush` on the goal item. When `true`, increment fires also `git push origin <branch>` after committing. Default is `off`.

Confirm:

```text
✅ Goal #[id] autopush: <on|off>
```

---

## Goal Fire Flow

When the auto-fire pulls a `kind: "goal"` item, route to one of two flows based on plan.md state.

### Planning fire (no plan, or empty plan)

This is the **first fire** for a goal. **No code is written.** The agent only produces a plan.

1. Spawn one general-purpose agent with this prompt template:

```text
Working directory: <goal.project>

You are the planning agent for a long-term goal. Your sole job is to write
a plan.md file. You will NOT write any code.

Goal: <goal.task>

Read the project state (git log -30, top-level file tree, README.md if it
exists, package.json or equivalent) and produce a numbered Markdown
checklist of small, mergeable, demoable increments toward the goal.

Each increment must:
- Be self-contained (no item depends on incomplete prior items)
- Be mergeable on its own (could ship as a single PR)
- Be small enough that one focused agent could finish it in one fire
- Have a clear "done" criterion

Write the checklist to: ~/blitz/goals/<goal.id>/plan.md

Format:
  # Plan: <goal.task>
  Project: <goal.project>
  Created: <date>

  ## Increments
  - [ ] 1. <one-line summary>: <2-3 sentence detail>
  - [ ] 2. ...

Also write a result file to <output_dir>/goal-<goal.id>-plan.md containing
the plan and a short paragraph explaining your reasoning (why these
increments, in this order).

Do NOT make any commits. Do NOT modify any project files.
```

2. After the agent finishes, update the goal item: `lastTouched = now`, `incrementCount` stays at 0.
3. The goal will hit the increment-fire flow on its next fire.

### Increment fire (plan.md exists with at least one unchecked item)

1. Read `~/blitz/goals/<goal.id>/plan.md`. If every item is `[x]`, the goal is done — set a marker comment in plan.md (`> Goal complete: YYYY-MM-DD`), update the goal item with `lastTouched = now`, and exit. Skip auto-promoting a "review and merge" task since the user knows from `/blitz goal list`.
2. Pick the lowest-numbered unchecked item.
3. Spawn one general-purpose agent with this prompt template:

```text
Working directory: <goal.project>

You are an increment agent for goal #<goal.id>: "<goal.task>"

The full plan is at ~/blitz/goals/<goal.id>/plan.md. The increment you must
implement is item #<N>: <item summary>.

Steps:
1. Switch to (or create from main) the long-lived branch: <goal.branch>.
   - git fetch origin; git checkout <goal.branch> 2>/dev/null || git checkout -b <goal.branch> main
   - git rebase main (only if no conflicts; otherwise stay on the branch as-is and note in result)
2. Implement item #<N>. Read enough of the codebase to do this correctly.
3. If the project has a test command and it runs in under 60 seconds, run
   it and confirm it passes. Detect the command from package.json scripts,
   pytest presence, or similar. If detection fails or tests are slow, skip
   them and note in the result.
4. Commit: git add -A && git commit -m "blitz(goal-<goal.id>): <item summary>"
5. If <goal.autoPush> is true, push: git push origin <goal.branch>
6. Update plan.md: change item #<N> from [ ] to [x], append a one-liner
   with the commit SHA: "      ✓ <commit-sha-short>: <one-line summary>"
7. Write a result file to <output_dir>/goal-<goal.id>-<slug>.md with:
   - Heading: # Goal #<goal.id> increment: <item summary>
   - What was done (bullet list of changes)
   - Why this approach
   - Branch + commit SHA + any push status
   - What's next (the next unchecked plan item, if any)

If the picked item is no longer applicable (e.g., already done by user, or
the codebase has changed in a way that invalidates it), mark it [~]
(skipped) with a one-line reason in plan.md and pick the next unchecked
item.

Hard rules:
- Only commit on <goal.branch>. Never on main.
- Never push unless <goal.autoPush> is true.
- Never edit plan.md items above the one you picked.
```

4. After the agent finishes, update the goal item: `lastTouched = now`, `incrementCount += 1`.

---

## M-AUDIT — Audit Lifecycle

Audits are per-project maintenance rotations that produce read-only reports. Audit items live in `backlog[]` with `kind: "audit"`. Audits never modify project files.

### M-AUDIT-ENABLE — Enable an audit rotation

Syntax: `/blitz audit enable <project>` (project may be a path or `.` for cwd)

1. Resolve the project to an absolute path. If a `kind: "audit"` item already exists for that project, print `Already enabled` and exit.
2. Append to `backlog[]`:

```json
{
  "id": <next>,
  "kind": "audit",
  "project": "<absolute path>",
  "rotation": ["security","deadcode","tests","deps","docs","todos"],
  "rotationIdx": 0,
  "lastSwept": null,
  "promotedFindings": []
}
```

3. Confirm:

```text
✅ Audit rotation enabled for <project>.
   Audits will rotate: security → deadcode → tests → deps → docs → todos.
   Run /blitz audit run <project> to trigger one immediately.
```

### M-AUDIT-DISABLE — Disable an audit

Syntax: `/blitz audit disable <project>`

Remove the matching `kind: "audit"` item. Confirm.

### M-AUDIT-LIST — Show enabled audits

Print one row per audit item: project, last-swept date, next audit type (`rotation[rotationIdx]`), promoted-finding count.

### M-AUDIT-RUN — Run the next audit immediately

Syntax: `/blitz audit run <project>`

Bypass the auto-fire scheduler and run the next audit type for this project right now. Same flow as Audit Fire Flow below.

## Audit Fire Flow

When the auto-fire pulls a `kind: "audit"` item:

1. Pick the next audit type: `audit_type = item.rotation[item.rotationIdx]`.
2. Spawn one general-purpose agent with this prompt template:

```text
Working directory: <audit.project>

You are an audit agent. Run the <audit_type> audit on this project. You
MUST NOT modify any project files. Output is read-only.

Audit type: <audit_type>

Definitions:
  security  - OWASP-style issues. Look for hardcoded secrets, SQL/command
              injection, unsanitized inputs, weak crypto, missing auth
              checks. Output: file:line + severity (high/medium/low).
  deadcode  - Unused exports, unreachable branches, orphaned files.
              Output: file:line + reason.
  tests     - Public functions/classes with no test coverage. Output:
              file:line + symbol name.
  deps      - Outdated packages, breaking-change risk. Output: package
              name + current → latest version + risk note.
  docs      - Public APIs (exports, public methods) without docstrings or
              JSDoc. Output: file:line + symbol name.
  todos     - TODOs/FIXMEs grouped by age (from git blame) and severity.
              Output: file:line + age + content.

Write a markdown report to <output_dir>/audit-<project_slug>-<audit_type>.md
with this structure:
  # <audit_type> audit — <project_slug>
  Date: <YYYY-MM-DD>
  Total findings: <N>

  ## Findings
  ### Finding 1: <one-line summary>
  Severity: <high|medium|low>
  Location: <file>:<line>
  Hash: <sha256 of: file_path + ":" + line + ":" + audit_type + ":" + finding_summary>
  Detail: <2-4 sentences>

  ### Finding 2: ...

Sort findings by severity (high first), then by file path.
```

3. After the agent finishes, the skill (not the agent) does:
   a. Read the report. Parse `Hash:` lines from each finding.
   b. Find the highest-severity finding whose hash is **not** in `item.promotedFindings`.
   c. If one exists, append a new `kind: "task"` item to `backlog[]`:

```json
{
  "id": <next>,
  "kind": "task",
  "task": "<finding summary> (<file>:<line>)",
  "project": "<audit.project>",
  "added": "<YYYY-MM-DD>",
  "source": { "auditId": <audit.id>, "auditType": "<audit_type>", "findingHash": "<sha256>" }
}
```

   d. Append the finding's hash to `item.promotedFindings`.
   e. Update `item.rotationIdx = (item.rotationIdx + 1) % len(item.rotation)`.
   f. Update `item.lastSwept = now`.
4. Save the config.

If every finding's hash is already in `promotedFindings`, the report is still written but no task is auto-promoted. The skill prints `All <audit_type> findings already promoted; nothing new to triage.`

---

## M-RUN — Run the Backlog (default `/blitz`)

This is the main path. Takes the top items off the backlog, spawns parallel agents, persists output.

### R1 — Check Backlog

If backlog is empty:
```
Backlog is empty. Add tasks with /blitz add <task description>.

Or, if you want to run anyway against the current project, type "auto" and I'll
generate generic improvement tasks for the current directory.
```
Wait for input. If the user says "auto", generate 3 generic tasks scoped to the current cwd (security audit, test gen, doc gen — concrete, not vague). Otherwise stop.

### R2 — Optional Urgency Read

Ask in one message:
> Quick: usage stats? `session: X% / Yh | weekly: X% / Yh` — or press Enter to skip.

If skipped, default to running 3 tasks (medium intensity). If provided, compute:
```
session_remaining = 100 - session_used
weekly_remaining  = 100 - weekly_used
session_rate = session_remaining / session_hours
weekly_rate  = weekly_remaining / weekly_hours
priority = max(session_rate, weekly_rate * 2)
```

Map score → number of tasks to pull from backlog:
| Score | Tasks to run |
|---|---|
| > 40 | 5–6 |
| 20–40 | 3–4 |
| 10–20 | 2–3 |
| < 10 | 1–2 |

If backlog has fewer items than that, run all of them.

### R3 — Show the Plan

```
╔══════════════════════════════════════════════════════╗
║                   ⚡ BLITZ — RUN PLAN                 ║
╠══════════════════════════════════════════════════════╣
║  Pulling [N] of [M] backlog items                    ║
║  Output: ~/blitz/runs/<timestamp>/                   ║
╚══════════════════════════════════════════════════════╝

  #1  <task>          [project]
  #2  <task>          [project]
  ...

Launch [N] parallel agents? (go / adjust / cancel)
```

If the user says "adjust", let them edit the list (skip a task, swap an id, etc.). On "go", proceed.

### R4 — Prepare Output Directory

Create `~/blitz/runs/<timestamp>/` where timestamp is `YYYY-MM-DD_HHMM-<trigger>` (trigger = `manual`, `weekly`, or `session`).

### R5 — Spawn Agents in Parallel

In **one** Agent tool call block (multiple `<invoke>` blocks in the same message), spawn one agent per task. Each agent prompt must include:

```
Working directory: <task.project>

Task: <task.task>

Produce thorough, long-form output. Show full work — code diffs, complete
implementations, line-by-line analysis where appropriate. Do not summarize
or truncate.

When you finish, write your full output to:
  <output_dir>/<task_id>-<short-slug>.md

Use the Write tool to create that file. Include a top-level heading with the
task description, then your full work.
```

Use `subagent_type: "general-purpose"` for code/writing tasks, `"Explore"` for pure research, `"Plan"` for architecture-only tasks. Default to general-purpose.

### R6 — Write Run Summary

After all agents complete, write `<output_dir>/_summary.md`:

```markdown
# Blitz run — <timestamp>

Trigger: <manual|weekly|session>
Tasks: <N> run in parallel

## Results
- [#1 task title](1-slug.md) — <one-line status from agent>
- [#2 task title](2-slug.md) — <one-line status>
...

## Backlog state after run
Removed: #1, #2, #3
Remaining: <N> items
```

Then **remove the completed tasks from the backlog** (so they don't get rerun next time).

### R7 — Final Report

```
╔══════════════════════════════════════════════════════╗
║                  ⚡ BLITZ COMPLETE                    ║
╠══════════════════════════════════════════════════════╣
║  Tasks done:  [N]                                    ║
║  Output:      ~/blitz/runs/<timestamp>/              ║
║  Backlog:     [N] items remaining                    ║
╚══════════════════════════════════════════════════════╝

Open the summary: <output_dir>/_summary.md
```

Tell the user the absolute path so they can click it.

---

## M-SETUP — Configuration Wizard

Six short steps. Show progress (`Setup 1/6`).

### S1 — Weekly Reset
> When does your weekly Claude quota reset? (e.g. "Mondays 9am EST")

Parse to: `weeklyReset.dayOfWeek` (0=Sun…6=Sat), `hour`, `minute`, `timezone`.

### S2 — Session Reset
> Roughly how often does your session reset, and when did the current one start?
> (e.g. "every 5 hours, started at 2pm")

Parse to: `sessionResetIntervalHours`, `sessionResetAnchorTime` ("HH:MM").

### S3 — Pre-Reset Lead Time
> How many minutes before reset should auto-blitz fire? (default: 45)

Store as `preResetMinutes`.

### S4 — Output Directory
> Where should agent output be written? (default: ~/blitz/runs)

Store as `outputDir`. Create the directory.

### S5 — Seed the Backlog (optional)
> Want to add some starter tasks now? (one per line, blank line to finish)
> Or skip and use /blitz add later.

Append any provided tasks to `backlog[]`.

### S6 — Auto-Schedule (opt-in, asked explicitly)
> Final question: enable auto-fire?
> I'll create scheduled jobs that run /blitz auto:
>   - Weekly: <day> at <fire-time> ([preResetMinutes] before reset)
>   - Session: every [N]h
>
> Anytime: /blitz off (disable), /blitz skip (skip next), /blitz on (re-enable)
>
> [Y] Enable auto-fire
> [N] Save config without scheduling

If **N**: save config, exit setup with confirmation.

If **Y**: detect OS, create the scheduled jobs, then **dry-run a test** (see S7).

#### Windows scheduled tasks

**Important:** Direct `cmd /c claude.exe ...` invocation fails silently from Task Scheduler context. Use a PowerShell wrapper script instead — verified working.

First, generate a wrapper script that the scheduled task will invoke:

```powershell
$claudePath  = (Get-Command claude -ErrorAction SilentlyContinue).Source
if (-not $claudePath) { throw "claude not found in PATH — install Claude Code first" }

$wrapperPath = "$env:USERPROFILE\.claude\blitz-runner.ps1"
$wrapperContent = @"
`$ErrorActionPreference = 'Continue'
`$logDir = `"`$env:USERPROFILE\blitz`"
New-Item -ItemType Directory -Force -Path `$logDir | Out-Null
`$log = `"`$logDir\blitz.log`"
`"=== Auto-fire `$(Get-Date) ===`" | Out-File `$log -Append -Encoding UTF8
& '$claudePath' -p '/blitz auto' 2>&1 | Out-File `$log -Append -Encoding UTF8
`"=== Done `$(Get-Date) ===`" | Out-File `$log -Append -Encoding UTF8
"@
Set-Content -Path $wrapperPath -Value $wrapperContent -Encoding UTF8

$action = New-ScheduledTaskAction -Execute "powershell.exe" `
  -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$wrapperPath`""

# Weekly trigger
$tw = New-ScheduledTaskTrigger -Weekly -DaysOfWeek <DayName> -At "<HH:MM>"
Register-ScheduledTask -TaskName "Blitz-Weekly" -Action $action -Trigger $tw -Force

# Session trigger (repeating)
$ts = New-ScheduledTaskTrigger -Once -At "<anchor>"
$ts.Repetition = (New-ScheduledTaskTrigger -Once -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Hours <N>) `
    -RepetitionDuration ([TimeSpan]::FromDays(365))).Repetition
Register-ScheduledTask -TaskName "Blitz-Session" -Action $action -Trigger $ts -Force
```

#### Mac/Linux crontab
```bash
(crontab -l 2>/dev/null | grep -v '# Blitz'; \
  echo "# Blitz weekly"; echo "<cron-expr> claude -p '/blitz auto'"; \
  echo "# Blitz session"; echo "<cron-expr> claude -p '/blitz auto'") | crontab -
```

`autoScheduleEnabled: true` in config.

### S7 — Verify Auth (important)
After creating the scheduled jobs, **immediately run a test**:

```
Testing: I'll trigger /blitz auto right now to confirm authentication works
in a non-interactive context. This will run with whatever's in your backlog
(or skip if empty).
```

On Windows: `Start-ScheduledTask -TaskName "Blitz-Session"` then check status.
On Mac/Linux: directly run `claude -p "/blitz auto"` in a subshell.

If it fails (auth not picked up in non-interactive context), tell the user clearly:
```
⚠ Auto-fire test failed: <error>

The scheduled jobs were created, but `claude` couldn't authenticate when run
non-interactively. Auto-mode won't work until this is fixed.

Workarounds:
  1. Manually run /blitz before each reset (still useful with the backlog)
  2. Disable auto-schedule: /blitz off
```

If it works, confirm:
```
✅ Auto-fire verified.
   Weekly:  fires <day> at <fire-time>
   Session: fires every <N>h
   Output:  <outputDir>
```

---

## M-AUTO — Unattended Scheduled Run

Triggered by the cadence-based scheduled job. **No interactive prompts.**

1. Load `~/.claude/blitz.json`. If missing or `autoScheduleEnabled` is false, exit silently.
2. If `skipNextFire` is true, set it to false, save, log `⚡ Auto-fire skipped (per /blitz skip)` to `~/blitz/blitz.log`, exit.
3. Run migration check (see "Migration v1 → v2"). If migrating, save and continue.
4. **Blackout window check**: get current weekday + time-of-day in the user's timezone. For each window in `firing.blackoutWindows`, if today's weekday is listed and current time falls in `[start, end)`, log `⚡ Blackout active`, exit.
5. **Pull items by tier**, respecting `firing.caps`:
   - First, walk `backlog[]` looking for `kind: "goal"` items. Take up to `caps.goalsPerFire` (default 1), preferring the goal with the oldest `lastTouched`.
   - Then walk for `kind: "task"` items. Take up to `caps.tasksPerFire` (default 3), in order added.
   - Then walk for `kind: "audit"` items. Take up to `caps.auditsPerFire` (default 1), preferring the audit with the oldest `lastSwept` (`null` sorts oldest).
6. **Per-item idle gate**: for each pulled item, run the gate check on its `project`:

```bash
# In the item's project directory:
RECENT_COMMIT=$(git log --since="<idleMinutes> minutes ago" --oneline | head -1)
DIRTY=$(git status --porcelain | head -1)
```

   - If `RECENT_COMMIT` is non-empty OR `DIRTY` is non-empty, **skip this item**. Leave it in the backlog; it will be eligible on the next fire.
   - If the project is not a git repo, the gate is bypassed (treated as idle).
7. If every pulled item was skipped: log `⚡ All targets active, deferring (next fire in <cadenceHours>h)` to `~/blitz/blitz.log`. Exit clean. Backlog unchanged.
8. Otherwise, prepare the output dir: `~/blitz/runs/<YYYY-MM-DD_HHMM>-cadence/`.
9. **Spawn agents in one parallel block**, one per non-skipped item, routed by kind:
   - `kind: "task"` → existing R5 prompt template.
   - `kind: "goal"` → Goal Fire Flow (planning or increment, based on plan.md).
   - `kind: "audit"` → Audit Fire Flow.
10. After all agents finish, run kind-specific post-processing:
    - For tasks: remove the task from `backlog[]` (current v0.1 behavior).
    - For goals: update `lastTouched` and `incrementCount`. Goal item stays in `backlog[]`.
    - For audits: parse the report, auto-promote one finding per Audit Fire Flow step 3. Audit item stays in `backlog[]`.
11. Write `<output_dir>/_summary.md` listing each item's result file with kind tag and one-line status.
12. Append a one-liner to `~/blitz/blitz.log`:

```text
[YYYY-MM-DD HH:MM] cadence-fire: ran <K> items (goals=<g>, tasks=<t>, audits=<a>); skipped <S>; output=<output_dir>
```

---

## M-OFF / M-ON / M-SKIP — Schedule Controls

**`/blitz off`** — set `autoScheduleEnabled: false` in config. Optionally also disable the OS jobs:
- Windows: `Disable-ScheduledTask -TaskName "Blitz-Weekly"` (and Session)
- Mac/Linux: comment out the `# Blitz` lines in crontab

Confirm: `🛑 Auto-fire disabled. Run /blitz on to re-enable, or /blitz manually anytime.`

**`/blitz on`** — reverse of off. Re-enable jobs and set `autoScheduleEnabled: true`.

**`/blitz skip`** — set `skipNextFire: true` in config. The next M-AUTO invocation will exit and reset the flag.
Confirm: `⏭ Next scheduled fire will be skipped. Subsequent fires will run normally.`

---

## Config Schema (v2)

```json
{
  "version": 2,
  "weeklyReset": {
    "dayOfWeek": 1,
    "hour": 9,
    "minute": 0,
    "timezone": "America/New_York"
  },
  "firing": {
    "mode": "hybrid",
    "cadenceHours": 3,
    "idleMinutes": 30,
    "blackoutWindows": [
      { "days": ["mon","tue","wed","thu","fri"], "start": "09:00", "end": "18:00" }
    ],
    "caps": { "goalsPerFire": 1, "tasksPerFire": 3, "auditsPerFire": 1 }
  },
  "outputDir": "~/blitz/runs",
  "goalsDir": "~/blitz/goals",
  "autoScheduleEnabled": true,
  "skipNextFire": false,
  "backlog": [
    {
      "id": 1,
      "kind": "task",
      "task": "Refactor auth.js for clarity",
      "project": "C:\\Users\\Adam\\repos\\myapp",
      "added": "2026-05-01"
    },
    {
      "id": 2,
      "kind": "goal",
      "task": "Ship pluginproof MVP",
      "project": "C:\\Users\\Adam\\MCP\\pluginproof",
      "added": "2026-05-04",
      "branch": "blitz/goal-2",
      "autoPush": false,
      "lastTouched": "2026-05-04T14:00:00Z",
      "incrementCount": 0
    },
    {
      "id": 3,
      "kind": "audit",
      "project": "C:\\Adam\\claude_skills",
      "rotation": ["security","deadcode","tests","deps","docs","todos"],
      "rotationIdx": 0,
      "lastSwept": null,
      "promotedFindings": []
    }
  ],
  "nextId": 4
}
```

Every backlog item has a `kind` field. Three kinds:
- `"task"` — a unit of work to run-and-remove (v0.1 behavior)
- `"goal"` — a long-term objective that produces increments via a durable plan
- `"audit"` — a per-project maintenance rotation that produces read-only reports

When adding any new item, increment `nextId` and use it as the new item's `id`.

## Migration v1 → v2

When the skill loads `~/.claude/blitz.json`, check `version`:

1. If `version` is `2`, do nothing.
2. If `version` is missing or `1`, run the migration:
   - Add `"kind": "task"` to every existing item in `backlog[]`.
   - Add a `firing` block with defaults: `{ "mode": "hybrid", "cadenceHours": 3, "idleMinutes": 30, "blackoutWindows": [], "caps": { "goalsPerFire": 1, "tasksPerFire": 3, "auditsPerFire": 1 } }`.
   - Drop `preResetMinutes` if present (functionality removed in v0.2).
   - Drop `sessionResetIntervalHours` and `sessionResetAnchorTime` if present (cadence model replaces session-anchored triggers).
   - Add `"goalsDir": "~/blitz/goals"` if missing.
   - Set `"version": 2`.
   - Save the file.
3. If on Windows and `autoScheduleEnabled` is `true`, replace existing `Blitz-Weekly` and `Blitz-Session` scheduled tasks with a single `Blitz-Cadence` task triggered every `cadenceHours`. On Mac/Linux, replace cron entries similarly.

Migration is idempotent — re-running it on a v2 config is a no-op.

---

## Principles

- **Real tasks only.** Backlog holds work the user actually wants done — never generated filler.
- **Persist everything.** Every agent writes to a file. Auto-fires that don't write artifacts are useless.
- **Parallel = throughput, not multiplier.** It finishes more tasks in the same wall-clock time. Don't oversell it.
- **Auto-fire is opt-in and reversible.** Always ask, always provide off/skip/on.
- **Verify auth on setup.** A scheduled job that silently fails auth is the worst possible outcome — test it during setup.
- **Empty backlog = no run.** Auto mode never invents work. If there's nothing queued, log and exit.
