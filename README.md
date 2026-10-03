# MARS Agent Skills

Curated Agent Skills used across MARS projects, originally imported from the owner's local catalog.

This repository is intentionally organized with each skill under `skills/<name>/SKILL.md`, so compatible skill installers can discover the catalog directly.

## Update the curated source

Make reviewed changes in this repository first. Preserve each skill's upstream attribution and notices, adapt project-specific examples to their actual applicability, and keep `SKILLS.txt` and both plugin manifests consistent. Project contracts, hardware constraints, toolchains, authorization, and `AGENTS.md` take precedence over reusable skill guidance.

Publishing source changes to GitHub and reimporting the plugin are separate operations. Reimport only when the owner authorizes it; a GitHub update does not update an already installed plugin.

### Legacy local mirror synchronization

The repository includes `scripts/sync-local-skills.ps1`, which copies the installed skills from:

- `~/.agents/skills`
- `~/.codex/skills`

It excludes Codex built-in `.system` skills and standalone `.vibeskills` installer state, normalizes lowercase `skill.md` to `SKILL.md`, rebuilds `SKILLS.txt`, commits the result, and pushes it to `main`. **It replaces the entire skill catalog. Do not run it with stale local copies: it can erase curated corrections and repository-only skills.** Compare and reconcile source changes first; use the script only when a complete local replacement is explicitly intended.

Run from Windows PowerShell:

```powershell
$tmp = "$env:TEMP\sync-mars-agent-skills.ps1"
Invoke-WebRequest "https://raw.githubusercontent.com/jonhys947/mars-agent-skills/main/scripts/sync-local-skills.ps1" -OutFile $tmp
powershell -ExecutionPolicy Bypass -File $tmp
```

This legacy script performs a complete mirror replacement; reviewed source edits are the normal update workflow.

## Install

When installation is authorized, install every skill globally:

```powershell
npx skills add https://github.com/jonhys947/mars-agent-skills --all -g -y
```

Install one skill:

```powershell
npx skills add https://github.com/jonhys947/mars-agent-skills --skill esp32-development -g -y
```

List what the installer discovers before installing:

```powershell
npx skills add https://github.com/jonhys947/mars-agent-skills --list
```

## Catalog

### ESP32 / embedded

- `esp32-development`
- `esp32-optimize`
- `cpp-memory-opt`
- `embedded-code-development`
- `embedded-firmware`
- `embedded-c-guidelines`
- `embedded-cpp-guidelines`
- `driver-review`
- `code-review-riscv`

### Review / engineering workflow

- `mars-orchestrator`
- `code-review`
- `karpathy-guidelines`
- `revisao-pr`
- `performance-core`
- `testing-standards`
- `dependency-management`
- `error-handling-core`
- `design-patterns-core`
- `api-design-standards`

### UI / design

- `frontend-design`
- `interface-design`
- `icon-design`
- `iconography-and-imagery`

### Documentation / planning

- `technical-writer`
- `design-architect`
- `memory-management`
- `prompt-engineering`
- `task-planner`

### Additional global skills

The repository also mirrors the other skills present in the local global catalog, including language-specific, shell, infrastructure, performance and Vibe tooling.

## Mirror policy

- The initial catalog came from locally installed skill directories supplied by the repository owner. Subsequent adaptations are reviewed in this repository.
- Codex built-in `.system` skills are intentionally **not mirrored**. They are runtime-provided system assets rather than user-installed skills.
- Standalone `.vibeskills` installer state is not treated as a skill.
- `http-error-diagnostics/skill.md` is normalized to `SKILL.md` for case-sensitive environments.
- Third-party skills remain the work of their upstream authors and remain subject to their upstream licenses and terms. This repository does not relicense third-party content. See [`SOURCES.md`](SOURCES.md).

## Project usage

For MARS projects, do not load the whole catalog by default. Project `AGENTS.md` files should select only the skills applicable to the current target and task.

Use `mars-orchestrator` when delegation or implementation supervision is authorized. It assigns ownership, checks the actual integration path for each requirement, and requires independent review and explicit evidence before claiming completion. Select agents and their model settings through the available runtime; skills do not configure models or create execution tools.

### Validation limits

Some imported skills retain client-specific frontmatter: `code-review-riscv` (`agent`, `context`, `disable-model-invocation`), `driver-review` (`disable-model-invocation`), `iconography-and-imagery` (`tags`), and `token-efficiency` (`autoload`). These existing fields are preserved rather than silently changing invocation behavior. The strict Codex skill-creator validator rejects those extensions; check compatibility with the intended installer separately. YAML parsing and static review do not prove installed runtime behavior. Reimport and runtime checks remain a separate authorized step.
