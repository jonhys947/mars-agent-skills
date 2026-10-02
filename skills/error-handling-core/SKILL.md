---
name: error-handling-core
description: Core error handling protocol for hybrid AI-human logging. Load language-specific skills separately.
---

# SKILL: Hybrid AI-Human Logging & Error Architecture

## Objective

Generate log outputs that serve two distinct consumers:
1. **Humans:** Verbose, natural language context for debugging
2. **AI Agents:** Deterministic, strongly-typed signals for instant graph retrieval

## The Protocol: Dual-Channel Logging

Every significant log event emits two signals.

### AI Channel Format

```
ai:<LEVEL> <CODE> [<KEY>=<VALUE>]...
```

**Examples:**
```
ai:ERROR E-156
ai:WARN E-042 retry_count=3 backoff_ms=1000
ai:INFO CHECKPOINT state=authenticated user_id=12345
```

**Constraint:** Error codes must map to defined type symbols (Class/Struct) in the codebase.

### Human Channel Format

Standard natural language logging with timestamps:
```
2024-02-01T10:00:00Z ERROR Connection refused: timeout after 30s (host=db.example.com)
```

## Type-Driven Errors

### The "Class-per-Error" Rule

Every unique AI error code must exist as a dedicated type in the codebase.

**Bad:** `logger.error("E-156: Token expired")` (String Literal)  
**Good:** `logger.error(new Error156())` (Typed Symbol)

### Why This Matters for AI

When AI reads `ai:ERROR E-156`:
1. **Symbol Lookup:** Maps `E-156` to struct/class `Error156`
2. **Graph Traversal:** Queries Code Property Graph for node `Error156`
3. **Instant Context:** Reveals definition, usage sites, remediation actions

### Naming Convention

* **Log Output:** `ai:ERROR E-156`
* **Type Name:** `Error156` or `Error156ConnectionRefused`
* **File Path:** `errors/network/error156.go` or `src/errors/network/Error156.ts`

## Log Level Protocol

| Level | AI Tag | Agent Action |
|-------|--------|--------------|
| INFO | `ai:INFO` | Record checkpoint |
| WARN | `ai:WARN` | Trigger retry logic |
| ERROR | `ai:ERROR` | Graph lookup for Type `E-{code}` |
| FATAL | `ai:FATAL` | Escalate to human |

## Error Code Ranges

- E-100 to E-199: Authentication
- E-200 to E-299: Network
- E-300 to E-399: Database
- E-400 to E-499: Validation

## Language-Specific Implementation

Load the appropriate skill for your language:
- **Go:** `skill("error-handling-go")`
- **TypeScript/JavaScript:** `skill("error-handling-ts")`

## Graph Queries for Error Analysis

```cypher
// Find error definition
MATCH (e:Type {name: "Error156"}) RETURN e.file, e.line

// Find usage sites
MATCH (e:Type {name: "Error156"})<-[:INSTANTIATES]-(call:CallSite)
RETURN call.file, call.line

// Find error propagation
MATCH (e:Type {name: "Error156"})<-[:THROWS]-(f1:Function)<-[:CALLS]-(f2:Function)
RETURN f1.name as thrower, f2.name as caller
```
