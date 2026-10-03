---
name: git-workflow
description: Standardized Git workflows, commit conventions, and release processes. Use for git operations, PRs, and release management.
---

# Git Workflow Standards

## Commit Message Convention

Follow the repository's commit convention. If it uses [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/), use that format; do not impose a new convention on a project that has another one.

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

Follow hooks that the repository actually configures, such as checks in `.pre-commit-config.yaml`. Treat Conventional Commit validation, secret scanning, and linting as examples only when those hooks are present.

## Pull Request Standards

### Guidelines

- Keep PRs short and concise.
- Link to relevant tickets when the project uses them and a related ticket exists.
- Focus on what changed and why.
- Include risk assessment for significant changes.

### PR Title Format

If the repository uses Conventional Commit titles, use that format. Otherwise follow its established PR title convention. For example:
```
feat(go-test): add coverage threshold support
fix(terraform-plan): handle workspace selection correctly
```

## Branching Strategy

Follow the user's instruction and the repository's established workflow. Do not create or switch branches as a routine step when the authorized task is to work in the current checkout.

### Branch Naming
If a new branch is requested or required by the project workflow, use its naming convention. For example:
```
feature/JIRA-123-add-oauth-support
bugfix/JIRA-456-fix-null-pointer
hotfix/JIRA-789-security-patch
release/v2.1.0
```

## Release Management

### Commits, Worktrees, and Checkpoints

- A reviewable diff is the default checkpoint. Commit only when the user or applicable project workflow authorizes it; group changes into coherent commits rather than committing every small step.
- Use a worktree only when requested or required by the established workflow. Do not remove a worktree or discard its state as automatic cleanup; first preserve any uncommitted work and follow the applicable authorization.
- When pushing an authorized branch, push the branch contents using the repository's normal remote workflow. Never treat worktree metadata or local paths as publishable content.

### Semantic Versioning
Use [Semantic Versioning](https://semver.org/) when the project follows it; otherwise use the project's versioning policy.

## Best Practices

### Before Committing
1. Run pre-commit hooks
2. Review changes with `git diff`
3. Stage only related changes
4. Write clear commit message
5. Verify no secrets included

### Before Creating a PR

Confirm the intended base and project CI, and run the checks that apply to the change. These are not automatic Git actions: do not fetch, rebase, squash, push, create or update a PR, or merge unless that specific action is authorized. Do not rewrite shared history. A review request alone does not authorize publishing a review or merging.
