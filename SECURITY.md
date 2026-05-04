# Security Policy

## Supported versions

Only the latest released version of Blitz is supported. Older versions do not receive fixes.

| Version | Supported |
| ------- | --------- |
| 0.2.x   | ✅        |
| < 0.2   | ❌        |

## Reporting a vulnerability

If you discover a security issue in this repo, please **do not open a public issue**. Report it privately via one of these channels:

- **GitHub private vulnerability report**: https://github.com/ADM-NKH/claude-blitz/security/advisories/new
- **Email**: adamnikh@gmail.com (subject: `claude-blitz security`)

Please include:

- A description of the issue and the impact you've identified.
- Steps to reproduce, or a minimal proof-of-concept.
- Any suggested mitigation, if you have one.

You should expect an acknowledgement within 7 days. Coordinated disclosure: once a fix is ready, we'll publish a release and credit the reporter (unless you ask not to be credited).

## Threat model — what's in scope

Blitz is a Claude Code skill: the artifact is `SKILL.md`, executed as instructions by the Claude model at runtime. Realistic security concerns for this project:

- **Install scripts.** `install.sh` and `install.ps1` download `SKILL.md` from `raw.githubusercontent.com/ADM-NKH/claude-blitz/main/SKILL.md` over HTTPS. A compromised `main` branch would deliver malicious instructions to every user who reinstalls. Mitigation: branch protection on `main`, 2FA on the maintainer account, signed releases (planned).
- **Skill prompt content.** The model interprets `SKILL.md` as instructions. A malicious edit could direct the model to write secrets, exfiltrate data, or modify files outside the working tree. Reviewers should treat any change to `SKILL.md` with the same care as a code-level security change.
- **OS scheduled job creation.** During `/blitz setup`, the skill creates a Windows Task Scheduler entry or a cron entry that runs `claude -p '/blitz auto'` on a cadence. Bad input to the wizard, or a future schema bug, could in theory write malformed scheduled jobs.
- **Git autonomy.** The goal-fire flow makes commits on `blitz/goal-<id>` branches. The hard rule "never main, never push without explicit `autoPush`" is enforced by prose. A malicious change to that prose would let the skill push to the user's remotes.

## Out of scope

- Vulnerabilities in Claude Code itself (report to Anthropic).
- Vulnerabilities in user-installed third-party MCPs or skills.
- Social-engineering attacks against the maintainer's GitHub account (covered by GitHub's general security model — 2FA, hardware keys, etc.).
