---
name: dependency-management
description: Standards for vetting, installing, and managing project dependencies. Use when adding new packages or libraries.
---

# Dependency Management Skill

## Purpose

Ensure dependencies are secure, compatible, and properly managed throughout their lifecycle. Balance velocity with security and maintainability.

## Pre-Approved Libraries

These libraries are pre-vetted and can be installed autonomously without asking permission:

### Testing Libraries
**JavaScript/TypeScript:**
- `fast-check` - Property-based testing
- `@faker-js/faker` - Test data generation
- `vitest` - Unit testing framework
- `jest` - Unit testing framework
- `@testing-library/react` - React component testing
- `@testing-library/dom` - DOM testing utilities
- `playwright` - E2E testing
- `cypress` - E2E testing

**Python:**
- `hypothesis` - Property-based testing
- `faker` - Test data generation
- `pytest` - Unit testing framework
- `pytest-cov` - Coverage reporting
- `pytest-mock` - Mocking utilities

**Go:**
- `github.com/stretchr/testify` - Testing toolkit
- `github.com/golang/mock` - Mocking framework
- `gopter` - Property-based testing
- `go-fuzz` - Fuzzing

### Development Tools
**JavaScript/TypeScript:**
- `eslint` - Linting
- `prettier` - Code formatting
- `typescript` - Type checking
- `ts-node` - TypeScript execution

**Python:**
- `black` - Code formatting
- `pylint` - Linting
- `mypy` - Type checking
- `ruff` - Fast linter

**Go:**
- `golangci-lint` - Comprehensive linting
- `gofmt` - Code formatting
- `staticcheck` - Static analysis

## Vetting Process for New Dependencies

When adding a dependency NOT on the pre-approved list:

### 1. Security Check
- **NPM**: Run `npm audit` after installation
- **Python**: Check with `pip-audit` or `safety check`
- **Go**: Run `govulncheck`
- **All**: Search for known CVEs at https://cve.mitre.org

### 2. Maintenance Assessment
Check these indicators:
- **Last updated**: Within 12 months (active maintenance)
- **GitHub stars**: >1000 for critical dependencies
- **Open issues**: <50 unresolved critical issues
- **Contributors**: >5 active contributors
- **Downloads**: High weekly download count

### 3. License Compatibility
Verify license is compatible with project:
- **Permissive (Safe)**: MIT, Apache 2.0, BSD, ISC
- **Weak Copyleft (Usually Safe)**: LGPL, MPL
- **Strong Copyleft (Ask First)**: GPL, AGPL
- **Proprietary (Ask First)**: Custom licenses

### 4. Bundle Size Impact (Frontend Only)
- Check bundle size at https://bundlephobia.com
- Avoid packages >100KB unless essential
- Prefer tree-shakeable packages

## Installation Standards

### Version Pinning
**Always pin versions for production dependencies:**

```json
// Good: Exact version
"dependencies": {
  "express": "4.18.2"
}

// Bad: Loose version
"dependencies": {
  "express": "^4.18.2"
}
```

**Use ranges for dev dependencies:**
```json
"devDependencies": {
  "vitest": "^1.0.0"
}
```

### Lockfile Hygiene
- **ALWAYS commit lockfiles**: `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `go.sum`, `poetry.lock`
- **Never manually edit lockfiles**
- **Regenerate after conflicts**: Delete and reinstall

### Installation Commands

**JavaScript/TypeScript:**
```bash
# NPM
npm install --save-exact <package>        # Production
npm install --save-dev <package>          # Development

# Yarn
yarn add --exact <package>
yarn add --dev <package>

# PNPM
pnpm add --save-exact <package>
pnpm add --save-dev <package>
```

**Python:**
```bash
# Pip with requirements.txt
pip install <package>
pip freeze > requirements.txt

# Poetry (preferred)
poetry add <package>
poetry add --group dev <package>
```

**Go:**
```bash
# Go modules
go get <package>@<version>
go mod tidy
```

## When to Ask Permission

**ALWAYS ask before installing if:**
1. Package is NOT on pre-approved list
2. License is GPL/AGPL or proprietary
3. Package has known security vulnerabilities
4. Package is unmaintained (>2 years since update)
5. Package adds >50MB to bundle size
6. Installing a major version upgrade (e.g., v2 → v3)

**Format for asking:**
```markdown
I need to install `<package>` for <reason>.

Security: <audit results>
Maintenance: Last updated <date>, <stars> stars
License: <license type>
Size: <bundle size if frontend>

Alternatives considered:
- <alternative 1>: <why not chosen>
- <alternative 2>: <why not chosen>

Approve installation?
```

## Dependency Updates

### Update Strategy
- **Security patches**: Apply immediately
- **Minor versions**: Monthly review
- **Major versions**: Quarterly review with testing

### Update Process
1. Check changelog for breaking changes
2. Update in isolated branch
3. Run full test suite
4. Check for deprecation warnings
5. Update documentation if API changed

### Automated Updates
Configure Dependabot/Renovate for:
- Security patches: Auto-merge if tests pass
- Minor updates: Create PR for review
- Major updates: Create PR with manual review required

## Supply Chain Security

### Best Practices
1. **Verify package integrity**: Check checksums/signatures
2. **Use private registry**: For internal packages
3. **Scan dependencies**: Regular vulnerability scanning
4. **Audit transitive deps**: Check what your deps depend on
5. **Use SBOMs**: Generate Software Bill of Materials

### Red Flags
**NEVER install packages that:**
- Have no source code repository
- Were published <7 days ago with no history
- Have suspicious install scripts
- Request unusual permissions
- Have typosquatting names (e.g., `reqests` instead of `requests`)

## Removal Process

When removing a dependency:
1. Search codebase for imports/usage
2. Remove from package.json/requirements.txt/go.mod
3. Run `npm prune` / `pip uninstall` / `go mod tidy`
4. Verify tests still pass
5. Check bundle size reduction

## Common Pitfalls

**Over-dependency**: Don't install a library for a simple function you can write in 10 lines.

**Outdated packages**: Regularly audit and update dependencies.

**Dev vs Prod confusion**: Keep dev dependencies separate.

**Ignoring warnings**: Address deprecation warnings promptly.

## Quick Reference

| Action | NPM | Python | Go |
|--------|-----|--------|-----|
| Install | `npm install --save-exact` | `poetry add` | `go get` |
| Install dev | `npm install --save-dev` | `poetry add --group dev` | N/A |
| Update | `npm update` | `poetry update` | `go get -u` |
| Audit | `npm audit` | `pip-audit` | `govulncheck` |
| Remove | `npm uninstall` | `poetry remove` | `go mod tidy` |
| List | `npm list` | `poetry show` | `go list -m all` |

## Integration with Agents

**QA Engineer**: Can autonomously install pre-approved testing libraries.

**System/UI/DevOps Engineers**: Must ask for non-pre-approved production dependencies.

**Tech Lead**: Reviews and approves dependency decisions.

**Security Engineer**: Audits dependencies during security review.
