---
name: git-workflow
description: Standardized Git workflows, commit conventions, and release processes. Use for git operations, PRs, and release management.
---

# Git Workflow Standards

## Commit Message Convention

All commits MUST follow [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/).

### Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Commit Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `build`: Changes to build system or dependencies
- `ci`: Changes to CI/CD configuration
- `chore`: Other changes that don't modify src or test files
- `revert`: Reverts a previous commit

### Breaking Changes

Indicate breaking changes with `!` after type/scope or `BREAKING CHANGE:` in footer.

## Pre-commit Hooks

Ensure pre-commit hooks are respected (usually defined in `.pre-commit-config.yaml`).
- **Commit Message Validation**: Enforces conventional commit format
- **Secret Detection**: Checks for credentials
- **Linting**: Shellcheck, Actionlint, etc.

## Pull Request Standards

### Guidelines

- Keep PRs short and concise.
- Link to relevant tickets (JIRA/Issues).
- Focus on what changed and why.
- Include risk assessment for significant changes.

### PR Title Format

Use conventional commit format:
```
feat(go-test): add coverage threshold support
fix(terraform-plan): handle workspace selection correctly
```

## Branching Strategy

### Branch Naming
Use descriptive names with ticket references:
```
feature/JIRA-123-add-oauth-support
bugfix/JIRA-456-fix-null-pointer
hotfix/JIRA-789-security-patch
release/v2.1.0
```

## Release Management

### Worktree & Checkpoint Protocol

*   **Micro-Commits:** Commit after *every* successful logical step (e.g., "created type", "passed test"). This acts as a "Save Point" for the agent.
*   **Worktree Hygiene:** NEVER push the worktree directory structure itself. Only push the *contents* (commits) of the branch.
*   **Abandonment:** If a worktree is abandoned (rollback), ensure `git worktree remove` is called to keep the filesystem clean.

### Semantic Versioning
Follow [Semantic Versioning 2.0.0](https://semver.org/): `MAJOR.MINOR.PATCH`.

## Best Practices

### Before Committing
1. Run pre-commit hooks
2. Review changes with `git diff`
3. Stage only related changes
4. Write clear commit message
5. Verify no secrets included

### Before Creating PR
1. Rebase on latest `main`
2. Squash commits if needed
3. Run full test suite locally
4. Verify CI checks pass
