# Changelog

All notable changes to Blitz will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] — 2026-05-04

### Added

- Goal lifecycle: `/blitz goal add|list|review|log|remove|autopush`. Goals decompose at run-time into a durable `plan.md`; first fire writes the plan, subsequent fires implement one increment each on a long-lived `blitz/goal-<id>` branch.
- Audit lifecycle: `/blitz audit enable|disable|list|run`. Per-project rotations across security, dead-code, test-gap, dependency, doc-gap, and TODO audits. Reports are read-only; one finding per audit auto-promotes to the backlog (idempotency-keyed by SHA-256 hash).
- Hybrid cadence + per-project idle-gate firing model. `firing.cadenceHours`, `firing.idleMinutes`, `firing.blackoutWindows`. Replaces v0.1's pre-reset-only model.

### Changed

- Backlog items now have a `kind` field (`"task" | "goal" | "audit"`).
- Setup wizard (`/blitz setup`) restructured: cadence + idle threshold + blackout windows replace session-anchor questions.
- M-AUTO now pulls items by tier with per-project idle gating.
- Schedule controls (`/blitz off`, `on`) now manage a single `Blitz-Cadence` task instead of separate weekly + session jobs. v0.1 task names are still cleaned up if present.

### Removed

- `preResetMinutes` config field and the pre-reset boost behavior. The cadence model fires steadily; manual `/blitz` covers explicit pre-reset runs.
- `sessionResetIntervalHours` and `sessionResetAnchorTime` config fields. Cadence model replaces session-anchored triggers.

### Migrated automatically

- v1 → v2 config migration runs on first load. Adds `kind: "task"` to existing backlog items, adds `firing` block with defaults, removes obsolete fields, replaces OS scheduled jobs.

## [0.1.0] — 2026-05-03

### Added

- Initial public release.
- Compatible with `npx skills add ADM-NKH/claude-blitz` via [vercel-labs/skills](https://github.com/vercel-labs/skills) — auto-detects the AI harness.
- `/blitz` — manual backlog run with parallel agent execution.
- `/blitz add`, `/blitz list`, `/blitz remove`, `/blitz clear` — backlog management.
- `/blitz setup` — interactive wizard for reset schedule, output directory, and optional auto-fire.
- `/blitz auto` — unattended pre-reset run, called from a scheduled job.
- `/blitz off`, `/blitz on`, `/blitz skip` — kill switches for auto-fire.
- Output persistence: every agent writes to `~/blitz/runs/<timestamp>/<id>-slug.md`.
- Per-run summary file (`_summary.md`) listing all completed tasks.
- Windows installer (PowerShell) and Mac/Linux installer (bash).
- Uninstaller for both platforms.
- Verified end-to-end: parallel agent spawning, output persistence, and Task Scheduler auth via PowerShell wrapper.
