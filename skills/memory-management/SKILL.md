---
name: memory-management
description: Standards for managing project memory, preventing conflicts, and maintaining knowledge quality. Use when reading, writing, or auditing project memory.
---

# Memory Management Skill

## Purpose

Maintain useful, current project memory without turning it into a second or competing source of truth. Project memory is supporting context: follow the user's instructions and the project's authoritative specifications, policies, and contracts when sources disagree.

## Memory Structure

```text
<project memory location, if the project defines one>/
  project.md      # Technical decisions, patterns, constraints
  human.md        # User preferences, communication style
  persona.md      # Agent personality and behavior
```

This is an illustrative layout, not a required `.opencode` directory or file set. Use the memory location and format the project already supports. Do not create a parallel memory store when none is configured.

## Memory Audit Protocol

### When to Trigger Audit

Consider an audit when the user or project workflow requests one, when a relevant conflict or obsolete entry is found, or when a substantial project change makes existing memory suspect. Do not assume a task counter, memory API, or automatic audit hook is available.

**Manual triggers:**
- The user or the project's designated memory owner requests an audit.
- A relevant conflict or major change makes existing memory suspect.

### Audit Process

1. **Read Available Memory**
   ```
   [Use the project's configured memory mechanism, if available.]
   ```

2. **Identify Issues**
   - Duplicate rules
   - Conflicting guidance
   - Obsolete patterns
   - Missing categories

3. **Categorize Content**
   Organize into logical sections:
   - Architecture Decisions
   - API Standards
   - UI/UX Patterns
   - Security Requirements
   - Performance Guidelines
   - Testing Strategy and Gates
   - Deployment Procedures

4. **Resolve Conflicts**
   When rules conflict:
   - First check the applicable authority: user instructions and current project specifications, policies, or contracts take precedence over memory and implementation history.
   - Within sources of equal authority, check scope, explicitness, and date. Recency alone does not override an authoritative requirement.
   - Treat code as evidence of current behavior, not proof that the behavior is the intended contract.
   - If an unresolved conflict changes the requested outcome, safety, or scope, surface it instead of silently choosing a side.
   - Record the source and rationale when the project authorizes memory updates.

5. **Handle Obsolete Content**
   If the project has an archive convention and the update is authorized, preserve useful history there. Otherwise annotate or propose the change using the existing memory workflow; do not create an archive path or delete history by default.

6. **Report Results**
   ```markdown
   Memory Audit Complete:
   - Conflicts resolved: X
   - Rules consolidated: Y
   - Items archived: Z
   - Current size: N lines
   ```

## Writing to Memory

### When to Write

**DO write when:**
- A durable project decision, constraint, or learning needs to be recorded and the project workflow authorizes the update.

**DON'T write when:**
- Information is already documented
- It's a one-time decision
- It's obvious from the code
- It's covered by existing skills

### Memory Entry Format

```markdown
## [Category]: [Topic]

**Context:** [Why this matters]

**Decision:** [What was decided]

**Rationale:** [Why this approach]

**Example:**
[Code or configuration example]

**Related:** [Links to requirements, design docs, or other memory entries]
```

### Example Entry

```markdown
## API Standards: Error Response Format

**Context:** Need consistent error responses across all API endpoints.

**Decision:** All errors return JSON with `error`, `message`, and `code` fields.

**Rationale:** Enables frontend to handle errors uniformly and provide better UX.

**Example:**
```json
{
  "error": "ValidationError",
  "message": "Email format is invalid",
  "code": "INVALID_EMAIL"
}
```

**Related:** See `src/middleware/errorHandler.ts`
```

## Conflict Resolution

Memory records decisions and context; it does not grant authority to override the user, current project policy, or a normative specification. When memory conflicts with a higher-authority source, follow that source and update or annotate the memory only when the task and project workflow authorize it.

### Detecting Conflicts

**Common conflict patterns:**
- "Use X" vs "Use Y" for the same purpose
- "Always do X" vs "Never do X"
- Contradictory version requirements
- Incompatible architectural patterns

### Resolution Strategy

1. **Authority Check**: Identify which source governs the decision.
2. **Scope Check**: Confirm the sources address the same project, version, and situation.
3. **Same-Level Tie-Break**: Consider explicitness and date, while checking implementation as evidence rather than authority.
4. **Escalate Material Ambiguity**: Ask the responsible person only when the unresolved conflict affects the outcome or risk.

### Conflict Documentation

When resolving conflicts, document the decision:

```markdown
## Resolution: [Date]

**Conflict:** "Use Axios" vs "Use Fetch"

**Analysis:** One note predates the current API contract, while the other describes an older implementation pattern.

**Decision:** Follow the current project contract for new work.

**Action:** Mark the superseded memory entry with a reference to the governing contract if memory updates are authorized.
```

## Memory Garbage Collection

### When to Review Size or Obsolescence
- Memory has become difficult to find or keep current.
- A major project change may have invalidated existing guidance.

### GC Process

1. **Identify Obsolete Content**
   - References to removed code
   - Deprecated library guidance
   - Superseded decisions

2. **Archive with Context**
   Use an archive only if the project defines one and the update is authorized; preserve useful context rather than silently deleting history.
   ```markdown
   # Example: <project memory location>/archive/2024-02-01.md
   
   ## Archived: API Standards: REST Endpoints
   
   **Reason:** Migrated to GraphQL
   **Date:** 2024-02-01
   **Replaced By:** See "API Standards: GraphQL Schema"
   
   [Original content...]
   ```

3. **Update References**
   - Update any cross-references
   - Add migration notes if needed

4. **Consolidate Duplicates**
   - Merge similar entries
   - Keep most comprehensive version

## Memory Categories

### Architecture Decisions
- System design choices
- Technology selections
- Integration patterns

### API Standards
- Endpoint conventions
- Request/response formats
- Authentication patterns

### UI/UX Patterns
- Component structure
- Styling approach
- Accessibility requirements

### Security Requirements
- Authentication rules
- Authorization patterns
- Data protection standards

### Performance Guidelines
- Optimization strategies
- Caching policies
- Resource limits

### Testing Strategies
- Test coverage requirements
- Testing frameworks
- Mock/stub patterns

### Deployment Procedures
- CI/CD configuration
- Environment setup
- Release process

## Best Practices

### Keep It Actionable
```markdown
✅ "Use environment variables for API keys. Never hardcode."
❌ "We should probably avoid hardcoding sensitive data."
```

### Be Specific
```markdown
✅ "Database queries timeout after 30 seconds. Use pagination for large datasets."
❌ "Database queries should be fast."
```

### Include Examples
Use an example when it makes the decision or behavior clearer.

### Link to Code
Reference actual files when possible:
```markdown
See implementation in `src/auth/jwt.ts`
```

### Date Important Decisions
```markdown
## [2024-01-15] Migration to TypeScript
```

## Memory Size Management

### When to Split
Split memory when distinct topics need different retrieval or ownership, or when the current structure is hard to navigate. Use the project's existing convention; for example:
```
<project memory location>/
  project.md              # Core patterns
  project-api.md          # API-specific
  project-database.md     # Database-specific
  project-frontend.md     # Frontend-specific
```

Update the applicable index or retrieval instructions when that is part of the authorized scope. Do not assume a specific memory agent exists.

## Integration with Agents

Use the memory owners and approval flow that the project actually defines. Do not assume role names, tools, or write permission that are not present.

## Quick Reference

| Action | Guidance | When |
|--------|----------|------|
| Read | Use the configured memory source | When stored context is relevant and available |
| Suggest/update | Use the project's authorized write path | When a durable decision or constraint needs recording |
| Audit | Follow the project's memory workflow | When requested or when relevant entries may be stale or conflicting |

## Common Pitfalls

**Over-documenting**: Don't write obvious things.

**Under-documenting**: Don't skip important decisions.

**Stale content**: Regular audits prevent obsolete guidance.

**No examples**: Every rule needs a code example.

**Vague language**: Be specific and actionable.
