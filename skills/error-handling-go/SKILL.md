---
name: error-handling-go
description: Go-specific error handling patterns. Requires error-handling-core.
---

# Go Error Handling Implementation

## Error Type Definition

```go
// errors/auth/error156.go
package auth

import (
    "context"
    "fmt"
    "time"
)

type Error156 struct {
    UserID    string
    ExpiresAt time.Time
}

func (e Error156) Error() string {
    return fmt.Sprintf("E-156: Authentication token expired for user %s at %s",
        e.UserID, e.ExpiresAt)
}

func (e Error156) Code() string { return "E-156" }
func (e Error156) Severity() string { return "HIGH" }

// Optional remediation
func (e Error156) Remediation() RemediationAction {
    return &RefreshTokenAction{UserID: e.UserID}
}
```

## Remediation Interface

```go
type RemediationAction interface {
    Name() string
    Execute(ctx context.Context) error
    Fallback() RemediationAction
}
```

## Dual-Channel Logger

```go
type HybridLogger struct {
    mode  string // "both", "ai", "human"
    level string
}

func (l *HybridLogger) Error(err error) {
    if coder, ok := err.(interface{ Code() string }); ok {
        if l.mode != "human" {
            fmt.Printf("ai:ERROR %s\n", coder.Code())
        }
    }
    if l.mode != "ai" {
        fmt.Printf("%s ERROR %s\n", time.Now().Format(time.RFC3339), err.Error())
    }
}
```

## Property-Based Testing

```go
func TestError156Properties(t *testing.T) {
    properties := gopter.NewProperties(nil)

    properties.Property("Error156 always returns code E-156", prop.ForAll(
        func(userId string) bool {
            err := auth.Error156{UserID: userId}
            return err.Code() == "E-156"
        },
        gen.AnyString(),
    ))

    properties.Property("Error message contains user ID", prop.ForAll(
        func(userId string) bool {
            if userId == "" { return true }
            err := auth.Error156{UserID: userId}
            return strings.Contains(err.Error(), userId)
        },
        gen.AnyString().SuchThat(func(s string) bool { return s != "" }),
    ))

    properties.TestingRun(t)
}
```
