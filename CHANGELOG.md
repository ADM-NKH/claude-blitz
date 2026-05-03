# Changelog

All notable changes to Blitz will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
