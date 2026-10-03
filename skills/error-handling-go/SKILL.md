---
name: error-handling-go
description: Go error handling patterns using the project's existing conventions.
---

# Go Error Handling

Use ordinary Go `error` values and the project's established package boundaries, logging, and response conventions. Do not add an error framework or dependency solely to follow this skill.

## Return and Wrap Errors

- Return errors to the layer that can recover, translate, or report them.
- Add operation context with `%w` when callers may need to inspect the underlying error.
- Use `errors.Is` for sentinel errors and `errors.As` for established typed errors.
- Define a sentinel or custom type only when callers need a stable classification or structured domain data. Do not create one type or code for every error message.
- Avoid exposing internal details or secrets in user-facing messages.

```go
func loadDocument(ctx context.Context, id string) (*Document, error) {
	doc, err := store.Load(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("load document %q: %w", id, err)
	}
	return doc, nil
}

// At a boundary that can choose the response or recovery:
if errors.Is(err, ErrNotFound) {
	return notFoundResponse()
}
logger.Error("load document failed", "document_id", id, "error", err)
```

Adapt logger calls, field names, and boundary placement to the repository. Do not log and return the same failure at every layer.

## Testing Error Behavior

Test the behavior callers rely on: classification, wrapping, recovery, or safe response. Prefer the project's existing test tools. For example, a wrapping test can assert `errors.Is(err, ErrNotFound)` without depending on the full error string.

Property-based or fuzz tests can help when there is a meaningful invariant over a broad input space, but are optional and do not justify adding a dependency by themselves.
