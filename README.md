# MARS Agent Skills

Personal mirror of the Agent Skills used across MARS projects.

This repository is intentionally organized with each skill under `skills/<name>/SKILL.md`, so compatible skill installers can discover the catalog directly.

## Install

Install every skill globally:

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

- Files are copied from the locally installed skill directories supplied by the repository owner.
- Codex built-in `.system` skills are intentionally **not mirrored**. They are runtime-provided system assets rather than user-installed skills.
- Local installer metadata such as `.vibeskills` lock files is not mirrored as a standalone skill.
- `http-error-diagnostics/skill.md` was normalized to `SKILL.md` for case-sensitive environments.
- Third-party skills remain the work of their upstream authors and remain subject to their upstream licenses and terms. This repository does not relicense third-party content. See [`SOURCES.md`](SOURCES.md).

## Project usage

For MARS projects, do not load the whole catalog by default. Project `AGENTS.md` files should select only the skills applicable to the current target and task.
