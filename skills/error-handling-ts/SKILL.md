---
name: error-handling-ts
description: TypeScript/JavaScript error handling patterns. Requires error-handling-core.
---

# TypeScript/JavaScript Error Handling Implementation

## Error Type Definition

```typescript
// src/errors/auth/Error156.ts
export interface RemediationAction {
    name: string;
    execute: () => Promise<boolean>;
    fallback?: RemediationAction;
}

export class Error156 extends Error {
    readonly code = "E-156";
    readonly severity = "HIGH";
    
    constructor(
        readonly userId: string,
        readonly expiresAt: Date
    ) {
        super(`E-156: Authentication token expired for user ${userId}`);
        this.name = "Error156";
    }

    remediation(): RemediationAction {
        return {
            name: "RefreshAuthToken",
            execute: async () => {
                await authService.refreshToken(this.userId);
                return true;
            },
            fallback: {
                name: "ReauthenticateUser",
                execute: async () => {
                    await authService.reauthenticate(this.userId);
                    return true;
                }
            }
        };
    }
}
```

## Dual-Channel Logger

```typescript
type LogMode = "both" | "ai" | "human";

class HybridLogger {
    constructor(
        private mode: LogMode = "both",
        private level: string = "info"
    ) {}

    error(err: Error & { code?: string }) {
        if (err.code && this.mode !== "human") {
            console.log(`ai:ERROR ${err.code}`);
        }
        if (this.mode !== "ai") {
            console.log(`${new Date().toISOString()} ERROR ${err.message}`);
        }
    }
}
```

## Property-Based Testing (fast-check)

```typescript
import fc from "fast-check";

describe("Error156 Properties", () => {
    it("always returns code E-156", () => {
        fc.assert(fc.property(
            fc.string(),
            fc.date(),
            (userId, expiresAt) => {
                const err = new Error156(userId, expiresAt);
                return err.code === "E-156";
            }
        ));
    });

    it("message contains user ID when non-empty", () => {
        fc.assert(fc.property(
            fc.string().filter(s => s.length > 0),
            fc.date(),
            (userId, expiresAt) => {
                const err = new Error156(userId, expiresAt);
                return err.message.includes(userId);
            }
        ));
    });

    it("remediation has fallback", () => {
        fc.assert(fc.property(
            fc.string(),
            fc.date(),
            (userId, expiresAt) => {
                const err = new Error156(userId, expiresAt);
                const remediation = err.remediation();
                return remediation.fallback !== undefined;
            }
        ));
    });
});
```
