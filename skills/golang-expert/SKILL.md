---
name: golang-expert
description: Expert guidance on Go development, architecture, best practices, and tooling (including golangci-lint). Use for any Go-related tasks.
---

# Go Expert Skill

## Overview

You are an expert in Go, microservices architecture, and clean backend development practices. Your role is to ensure code is idiomatic, modular, testable, and aligned with modern best practices and design patterns.

## Architecture Patterns

- Apply **Clean Architecture** by structuring code into handlers/controllers, services/use cases, repositories/data access, and domain models.
- Use **domain-driven design** principles where applicable.
- Prioritize **interface-driven development** with explicit dependency injection.
  - **Contract First:** Define `type` and `interface` definitions (Skeleton) *before* implementing the logic (Flesh).
- Prefer **composition over inheritance**; favor small, purpose-specific interfaces.
- Ensure that all public functions interact with interfaces, not concrete types.

## Project Structure Guidelines

- Use a consistent project layout:
  - `cmd/`: application entrypoints
  - `internal/`: core application logic (not exposed externally)
  - `pkg/`: shared utilities and packages
  - `api/`: gRPC/REST transport definitions and handlers
  - `configs/`: configuration schemas and loading
  - `test/`: test utilities, mocks, and integration tests
- Group code by feature when it improves clarity and cohesion.
- Keep logic decoupled from framework-specific code.

## Development Best Practices

- Write **short, focused functions** with a single responsibility.
- Always **check and handle errors explicitly**, using wrapped errors for traceability (`fmt.Errorf("context: %w", err)`).
- Avoid **global state**; use constructor functions to inject dependencies.
- Leverage **Go's context propagation** for request-scoped values, deadlines, and cancellations.
- Use **goroutines safely**; guard shared state with channels or sync primitives.
- **Defer closing resources** and handle them carefully to avoid leaks.
- Use **Functional Options Pattern** for configuration and dependency injection where structs have more than 2 fields and are part of a public api.
- Use sensible defaults when creating **constructors** (`func NewThing() {}`).

## Security and Resilience

- Apply **input validation and sanitization** rigorously.
- Use secure defaults for **JWT, cookies**, and configuration settings.
- Implement **retries, exponential backoff, and timeouts** on all external calls.
- Use **circuit breakers and rate limiting** for service protection.

## Testing

- Write **unit tests** using table-driven patterns and parallel execution.
- **Mock external interfaces** cleanly using generated or handwritten mocks.
- Separate **fast unit tests** from slower integration and E2E tests.
- Ensure **test coverage** for every exported function.

## Observability

- Use **OpenTelemetry** for distributed tracing, metrics, and structured logging.
- Start and propagate tracing **spans** across all service boundaries.
- Use **log correlation** by injecting trace IDs into structured logs.
- Trace all **incoming requests** and propagate context through internal and external calls.

## Design Patterns

Use an established design pattern to help maintainability and understanding of code.

Use the `design-patterns-go` mcp to access details and examples of any of the below patterns.

ALWAYS consider what design pattern(s) are currently in use to help with single responsibility.

### Creational Patterns

These patterns provide various object creation mechanisms, which increase flexibility and reuse of existing code.

- Factory Method
- Abstract Factory
- Builder
- Prototype
- Singleton

### Structural Patterns

These patterns explain how to assemble objects and classes into larger structures while keeping these structures flexible and efficient.

- Adapter
- Bridge
- Composite
- Decorator
- Facade
- Flyweight
- Proxy

### Behavorial Patterns

- Chain of Responsibility
- Command
- Iterator
- Mediator
- Memento
- Observer
- State
- Strategy
- Template Method
- Visitor

## Linting and Quality (golangci-lint)

### Core Philosophy
**Fix the code first, configure second.** When golangci-lint reports issues, fix the code. Only adjust configuration if truly necessary.

### Common Issues
- **errcheck**: Always check errors. `if err := file.Close(); err != nil { ... }`
- **cyclop**: Keep cyclomatic complexity ≤ 10. Refactor complex functions.
- **gosec**: Avoid hardcoded secrets. Use environment variables.

### Configuration
The project uses `.golangci.yml`. Common settings:
```yaml
linters-settings:
  cyclop:
    max-complexity: 10
  gocognit:
    min-complexity: 30
  funlen:
    lines: 60
    statements: 40
  lll:
    line-length: 120
    tab-width: 1

linters:
  enable:
    - cyclop
    - gocognit
    - funlen
    - lll
    - gocritic

issues:
  exclude-rules:
    # Exclude line length for generated files
    - path: '(.+)_gen\.go$'
      linters:
        - lll
    - path: '(.+)\.pb\.go$'
      linters:
        - lll
    # Exclude line length for test files with long table entries
    - path: '(.+)_test\.go$'
      linters:
        - lll
```

**Note**: golangci-lint doesn't have built-in file length checking. Consider custom tooling or manual review for files exceeding limits.

## Complexity Standards

- **Cyclomatic Complexity**: ≤10 (Acceptable), >15 (Critical - Refactor)
- **Cognitive Complexity**: ≤30 (Acceptable), >50 (Critical - Refactor)
- **Function Length**: ≤60 lines, ≤40 statements

### Refactoring Strategies
1. **Extract Helper Functions**: Break complex logic into smaller, focused functions.
2. **Use Early Returns**: Reduce nesting depth by returning early from error conditions.

## File Organization Standards

### File Length Limits

**Production Code**:
- **Soft limit**: 200 lines (ideal - encourages focused, single-purpose files)
- **Medium limit**: 600 lines (acceptable with clear justification)
- **Hard limit**: 1000 lines (critical - must refactor)

**Test Code** (1.5x multiplier for table-driven tests):
- **Soft limit**: 300 lines
- **Medium limit**: 900 lines
- **Hard limit**: 1500 lines

**Exceptions**:
- Generated code (protobuf, mocks, code-gen tools)
- Configuration files (large config structs)
- Migration files are NOT exempt - keep them focused

### Line Length Standards

- **Soft limit**: 120 characters (preferred for readability)
- **No hard limit** (pragmatic for complex expressions, long URLs, error messages)

Go community typically uses 100-120 characters. Favor brevity but don't sacrifice clarity with awkward line breaks.

### When to Split Files

Split files when:
1. **Multiple responsibilities**: File handles unrelated concerns
2. **Poor cohesion**: Functions don't work together toward a common purpose
3. **Hard to navigate**: Difficult to find specific functionality
4. **Test complexity**: Test file mirrors an oversized implementation file

### Refactoring Oversized Files

**By Feature**: Group related types, interfaces, and functions into feature-specific files
```
user.go          → user_service.go, user_repository.go, user_models.go
```

**By Layer**: Separate by architectural layer
```
handlers.go      → user_handler.go, order_handler.go, product_handler.go
```

**By Interface**: Extract interfaces and implementations
```
storage.go       → storage_interface.go, s3_storage.go, local_storage.go
```

## Key Conventions

1. Prioritize **readability, simplicity, and maintainability**.
2. Design for **change**: isolate business logic.
3. Emphasize clear **boundaries** and **dependency inversion**.
4. Ensure all behavior is **observable, testable, and documented**.
