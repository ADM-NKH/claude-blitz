# Contributing to Blitz

Thanks for the interest. Blitz is small and the surface area is intentional —
keep that in mind when proposing changes.

## Ways to contribute

- **Bug reports** — open an issue with the bug report template. Include OS,
  Claude Code version, and steps to reproduce.
- **Feature ideas** — open an issue with the feature request template before
  writing code, so we can discuss scope.
- **Pull requests** — see below.

## Pull request flow

1. Fork the repo and create a topic branch off `main`.
2. Make your change. Keep it focused — one PR per concern.
3. Update `CHANGELOG.md` under the `## [Unreleased]` section.
4. If you change the SKILL contract (commands, config schema, output paths),
   update the `README.md` accordingly.
5. Open the PR. Fill in the template.

## Style

- Markdown: 100-column soft wrap, fenced code blocks with language tags.
- Bash: pass `shellcheck` (CI runs it).
- PowerShell: pass `PSScriptAnalyzer` if possible.
- Be honest in claims. Don't oversell what the skill does.

## What's likely to be merged

- Better OS detection or schedule edge cases (DST, timezone handling).
- Improvements to the install/uninstall UX.
- Better Mac/Linux testing — the Windows path is verified end-to-end; the
  bash path is less battle-tested.
- Documentation clarity.

## What's unlikely

- Anything that frames Blitz as a "quota multiplier." Parallelism is for
  throughput, not for inflating quotas. The framing matters.
- Generated-filler tasks. Empty backlog → no run. That's by design.

## Code of conduct

Be kind. Be specific. Show your work.
