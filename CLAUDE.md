# CLAUDE.md

Guidance for Claude Code agents working in this repo.

## What this repo is

`claude-blitz` is a Claude Code skill, distributed publicly. The deliverable is a **single Markdown file** — `SKILL.md` — that the model reads and follows at runtime. There is no compiled artifact, no source code, no test suite. SKILL.md is the program; everything else is documentation, install scripts, and CI plumbing.

## Honesty pivot — never reintroduce "burn quota" framing

An earlier prototype (`max-mode`) was scrapped because it framed itself as "burn quota before reset." That framing was both TOS-risky and dishonest — parallelism does not multiply quota. v0.1 pivoted to a backlog runner: real, user-defined work only. v0.2 extended to goals + audits + cadence firing, still real-work-only.

These principles are non-negotiable in any change:

- **Real work only.** Empty backlog + no enabled audits = silent exit. Never invent filler tasks.
- **Parallelism is throughput, not a multiplier.** It finishes more tasks in the same wall-clock time.
- **No "burn quota," no "100% subscription," no "max out your plan" language** in SKILL.md, README, CHANGELOG, or any user-facing surface.

If an idea reintroduces this framing, reject it. The Principles section in `SKILL.md` is the canonical list of hard rules.

## Where things live

- `SKILL.md` — the artifact. Edit this for behavior changes.
- `README.md`, `CHANGELOG.md`, `VERSION` — user-facing.
- `install.{sh,ps1}` / `uninstall.{sh,ps1}` — install scripts. They download the latest `SKILL.md` from `main` and overwrite the local copy.
- `docs/superpowers/specs/` — design specs. **Add a spec here before any non-trivial change to SKILL.md.**
- `docs/superpowers/plans/` — implementation plans derived from specs.
- `.github/workflows/ci.yml` — CI. Lints README/CHANGELOG/CONTRIBUTING/.github/, runs shellcheck on install scripts.
- `.markdownlint.json` — lint config.

## Schema changes need a migration

The skill stores config at `~/.claude/blitz.json` with a `version` field. If you change the schema, you must:

1. Bump the version (e.g. `2` → `3`).
2. Add a `## Migration vN → vN+1` section to SKILL.md describing the transformation.
3. Make migration **idempotent** — re-running it on already-migrated config is a no-op.
4. Make migration **additive** where possible — don't destructively rename fields without a fallback read.
5. Update the example schema in SKILL.md and the v1→v2 migration's downstream references.

## Validation commands

There are no traditional tests. These are the closest equivalents:

```bash
# JSON examples in SKILL.md (placeholder/template blocks containing <foo> are skipped)
python -c "
import re, json, sys
content = open('SKILL.md', encoding='utf-8').read()
blocks = re.findall(r'\`\`\`json\n(.*?)\n\`\`\`', content, re.S)
fail = 0
for i, b in enumerate(blocks, 1):
    if re.search(r'<\w[\w. ]*>', b):
        print(f'  Block {i}: skipped (template placeholder)'); continue
    try: json.loads(b); print(f'  Block {i}: ok')
    except json.JSONDecodeError as e: fail += 1; print(f'  Block {i}: FAIL — {e.msg}')
sys.exit(1 if fail else 0)
"

# YAML frontmatter
python -c "import yaml; print(yaml.safe_load(open('SKILL.md', encoding='utf-8').read().split('---')[1]))"

# Markdown lint (CI scope)
npx -y markdownlint-cli README.md CHANGELOG.md CONTRIBUTING.md

# Step 0 routing coherence — every subcommand maps to a defined section
grep -nE '^## M-' SKILL.md
```

## Conventions

- **Branches.** Feature work on feature branches. PR into `main`. Do not push to `main` directly.
- **Commit messages.** Conventional-ish: `feat(skill): ...`, `docs: ...`, `fix: ...`, `chore: ...`. Subject line ≤ 80 chars.
- **No "Generated with Claude" footers** in commits, PR bodies, or any artifact.
- **Don't lint SKILL.md.** It's intentionally excluded from CI lint — its prose includes verbatim agent prompts, code fences inside code fences, and other structures that markdownlint flags as false positives.
- **Don't add features without a spec.** Drop a markdown design doc in `docs/superpowers/specs/YYYY-MM-DD-<topic>.md` first; turn it into a plan in `docs/superpowers/plans/` before editing `SKILL.md`.

## Common gotchas

- The frontmatter `description:` field is parsed by upstream skill installers; keep it on a single line and under ~600 chars.
- Inner code fences inside SKILL.md (e.g. ` ```text ` blocks inside an agent prompt template) need to remain — they're part of the prose contract with the agent runtime, not just decoration.
- Several JSON blocks in SKILL.md use placeholder syntax like `<next>` and `<absolute path>`. They're documentation templates, not literal JSON. Validators must skip them (see the snippet above).
- The install scripts hardcode a version string for display. Bump `$Version` in `install.ps1` and the equivalent in `install.sh` when releasing.

## When in doubt

Read `SKILL.md`'s **Principles** section. If the change you're considering would violate one of those bullets, the change is wrong, not the principle.
