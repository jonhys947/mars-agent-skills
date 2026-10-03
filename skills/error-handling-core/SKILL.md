---
name: error-handling-core
description: Language-agnostic error handling guidance. Load language-specific skills separately when relevant.
---

# Error Handling Core

## Objective

Handle failures so callers can make the right decision and maintainers can diagnose them. Follow the repository's existing error types, logging, tracing, and observability conventions. Do not add a parallel error or logging protocol just for an agent.

## Error Representation

Use the language's normal error mechanism first. Add a domain error type or stable code only when the application contract or a caller needs to distinguish that failure. Reuse established types where possible; do not create a dedicated type for every message or code.

Preserve the original cause and useful operation context when wrapping an error. Avoid including secrets or unnecessary personal data in messages and fields.

## Logging and Recovery

- Use the project's configured logger or tracing system and its structured fields where available. A normal log entry is sufficient; do not require duplicate "AI" and human channels.
- Handle or report an error at the layer that can take action. Avoid logging the same error at every layer as it propagates.
- Choose severity and retry behavior from the application's policy and the failure context. A warning does not automatically mean retry, and an error does not automatically mean fatal.
- Keep remediation, retries, and recovery explicit in the owning application flow. Merely classifying an error must not trigger a side effect.

## Finding Error Context

Start with the evidence available in the repository: call sites, existing logs, tests, traces, and documented behavior. Use code search, IDE indexes, or a code graph only when that tool is already available and its supported interface is known. Do not assume a graph database, schema, query language, or external service exists.

## Language-Specific Guidance

Load the appropriate skill for your language:
- **Go:** `skill("error-handling-go")`
- **TypeScript/JavaScript:** `skill("error-handling-ts")`

Load the language-specific skill when it applies. Use the dependencies, logger, and error conventions already present in the project; examples in a language skill are patterns to adapt, not a mandate to add a package or a new architecture.
