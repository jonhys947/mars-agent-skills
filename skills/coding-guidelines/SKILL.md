---
name: coding-guidelines
description: General coding principles, complexity standards, and best practices. Use as a baseline for code quality and review.
---

# General Coding Guidelines

## Core Principles
- **Language**: English for all code, comments, and names.
- **Idiomatic Style**: Follow official style guides for the target language.
- **Clarity**: Prioritize readability over cleverness.
- **Return Early**: Use `if (!condition) { return; }` to reduce nesting.
- **KISS & DRY**: Keep it simple, don't repeat yourself.

## Naming & Structure
- **Descriptive Names**: Explicit over abbreviated.
- **Single Responsibility**: Small, focused functions/classes.
- **Verbs for Functions**: `calculateTotal`, `fetchData`.
- **Nouns for Data**: `user`, `orderList`.

## Error Handling
- **Explicit Handling**: Handle errors with language-appropriate mechanisms.
- **Fail Fast**: Validate inputs early.
- **Context**: Provide clear error messages for debugging.

## Security
- **Validate Inputs**: Sanitize all external inputs.
- **Secrets**: Never hardcode secrets. Use environment variables.
- **Least Privilege**: Minimal permissions for DBs, files, APIs.

## Complexity Standards

Maintain code quality by enforcing complexity thresholds.

### Function-Level Metrics
- **Cyclomatic Complexity**: 
  - **≤10**: Acceptable
  - **11-15**: Warning (Refactor)
  - **>15**: Critical (Must Refactor)
- **Cognitive Complexity**:
  - **≤30**: Acceptable
  - **>30**: Warning
  - **>50**: Critical
- **Function Length**:
  - **Lines**: ≤60
  - **Statements**: ≤40

### Refactoring Strategies
- **Extract Helper Functions**: Break down large functions.
- **Use Early Returns**: Flatten nested logic.

### Process Integration (Chain of Code)
To consistently meet these complexity standards:
- **Draft First**: Use the **Chain of Code (CoC)** protocol to draft your interface and logic structure *before* implementation.
- **Simulate**: "Run" the draft in your head. If the draft looks complex, the code will be worse. Refactor the draft.

## File & Line Length Standards

### File Length Limits

**Production Code**:
- **Soft limit**: 200 lines (ideal - encourages focused modules)
- **Medium limit**: 600 lines (acceptable with justification)
- **Hard limit**: 1000 lines (critical - must refactor)

**Test Code** (1.5x multiplier for table-driven patterns):
- **Soft limit**: 300 lines
- **Medium limit**: 900 lines
- **Hard limit**: 1500 lines

**Exceptions**:
- Generated code (protobuf, OpenAPI, code-gen tools)
- Configuration files (large config definitions)
- Migration files are NOT exempt

### Line Length Standards

- **Soft limit**: 120 characters (preferred)
- **No hard limit** (pragmatic for URLs, error messages, complex expressions)

Favor brevity but prioritize readability over strict character counts.

### Rationale

**Why 200 lines?**
- Fits on a single screen with context
- Encourages single responsibility
- Easier to test and review

**Why 1000 line hard limit?**
- Beyond this, files become unmaintainable
- Navigation and comprehension suffer
- Indicates architectural issues

**Why 120 characters?**
- Modern standard across languages
- Balances readability with screen real estate
- Accommodates side-by-side diffs

### When to Split Files

Split when:
1. Multiple unrelated responsibilities
2. Difficult to navigate or find functionality
3. Poor cohesion between components
4. Approaching medium/hard limits

### Refactoring Strategies

**By Responsibility**: Separate distinct concerns into focused files
**By Layer**: Split by architectural boundaries (handlers, services, repositories)
**By Feature**: Group related functionality into feature modules
**By Type**: Extract interfaces, implementations, and models

## Documentation
- **Why, not What**: Document intent and decisions.
- **Public API**: Document purpose, parameters, returns.
- **Keep Current**: Update comments when code changes.

## Testing
- **Deterministic**: Use fixed test data.
- **Coverage**: Test happy paths, edge cases, and errors.
- **Descriptive Naming**: Reflect the scenario being tested.
