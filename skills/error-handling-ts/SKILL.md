---
name: error-handling-ts
description: TypeScript and JavaScript error handling patterns using existing project conventions.
---

# TypeScript/JavaScript Error Handling

Use the application's existing error classes, promise conventions, logger, and response mapping. Do not add a custom error framework or dependency solely to follow this skill.

## Represent and Propagate Failures

- Preserve the original cause when adding operation context. Use the built-in `cause` option only when the project's runtime and TypeScript target support it; otherwise use the established wrapper pattern.
- Add a domain-specific `Error` subclass only when callers need stable classification or structured data. Reuse shared error types rather than creating one class per message or code.
- Catch an error only when the current layer can recover, translate, or add useful context. Otherwise let the existing error path handle it.
- Keep internal details and secrets out of user-facing messages.

```typescript
try {
  return await store.loadDocument(id);
} catch (cause) {
  throw new Error(`load document ${id} failed`, { cause });
}
```

This is an illustrative wrapper. Confirm `Error` cause support for the project's runtime and target before using this exact form.

## Logging and Recovery

- Log through the configured logger at a boundary that can act on the failure, and avoid logging the same error at every layer.
- Follow the application's severity and retry policy. A log level alone does not decide whether to retry, return a response, or escalate.
- Keep retries and remediation explicit in the owning flow; classifying an error should not itself trigger side effects.

## Testing Error Behavior

Test the caller-visible behavior: preserved cause or classification, recovery, response mapping, and relevant edge cases. Use the project's existing test runner and assertion style. Property-based tests are optional when an invariant over a broad input space benefits from them; do not add a package just to use one.
