---
name: memory-management
description: Standards for managing project memory, preventing conflicts, and maintaining knowledge quality. Use when reading, writing, or auditing project memory.
---

# Memory Management Skill

## Purpose

Maintain high-quality, conflict-free project memory that serves as the "living documentation" of project decisions, patterns, and constraints.

## Memory Structure

```
.opencode/memory/
  project.md      # Technical decisions, patterns, constraints
  human.md        # User preferences, communication style
  persona.md      # Agent personality and behavior
```

## Memory Audit Protocol

### When to Trigger Audit

**Automatic triggers:**
- Every 10 completed tasks
- When `memory_read(block="project")` returns >500 lines
- When conflicting rules are detected
- Before major feature work begins

**Manual triggers:**
- Tech Lead requests "Memory Audit"
- Project Knowledge agent detects conflicts
- After major refactoring or architecture changes

### Audit Process

1. **Read Current Memory**
   ```
   memory_read(block="project")
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
   - Testing Strategies
   - Deployment Procedures

4. **Resolve Conflicts**
   When rules conflict:
   - Identify which is more recent
   - Check which aligns with current codebase
   - Flag for Tech Lead review if unclear
   - Document resolution reasoning

5. **Archive Obsolete Content**
   Move outdated patterns to `memory/archive/YYYY-MM-DD.md`

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
- Discovering a new project pattern
- Making an architectural decision
- Identifying a constraint or limitation
- Learning from a mistake or bug
- Establishing a new standard

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

### Detecting Conflicts

**Common conflict patterns:**
- "Use X" vs "Use Y" for the same purpose
- "Always do X" vs "Never do X"
- Contradictory version requirements
- Incompatible architectural patterns

### Resolution Strategy

1. **Timestamp Check**: Prefer more recent guidance
2. **Codebase Alignment**: Prefer what matches current code
3. **Scope Check**: Ensure rules apply to same context
4. **Tech Lead Review**: Escalate if unclear

### Conflict Documentation

When resolving conflicts, document the decision:

```markdown
## Resolution: [Date]

**Conflict:** "Use Axios" vs "Use Fetch"

**Analysis:**
- Axios rule added: 2023-05-10
- Fetch rule added: 2024-01-15
- Current codebase: 80% Fetch, 20% Axios

**Decision:** Standardize on Fetch API

**Action:** Archived Axios rule. New code uses Fetch.

**Migration:** Existing Axios code can remain until refactored.
```

## Memory Garbage Collection

### Triggers
- Memory file exceeds 1000 lines
- >20% of content is obsolete
- Major version upgrade or refactoring

### GC Process

1. **Identify Obsolete Content**
   - References to removed code
   - Deprecated library guidance
   - Superseded decisions

2. **Archive with Context**
   ```markdown
   # memory/archive/2024-02-01.md
   
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
Every rule should have a code example showing correct usage.

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

### Target Sizes
- **project.md**: 300-800 lines (optimal)
- **human.md**: 50-200 lines
- **persona.md**: 100-300 lines

### When to Split
If project.md exceeds 1000 lines, consider splitting:
```
.opencode/memory/
  project.md              # Core patterns
  project-api.md          # API-specific
  project-database.md     # Database-specific
  project-frontend.md     # Frontend-specific
```

Update Project Knowledge agent to read all files.

## Integration with Agents

**Project Knowledge**: Primary owner. Performs audits and GC.

**Tech Lead**: Writes architectural decisions after major features.

**All Engineers**: Can suggest memory entries via Tech Lead.

**Product Owner**: Reads memory to understand constraints.

## Quick Reference

| Action | Tool | When |
|--------|------|------|
| Read | `memory_read(block="project")` | Before any task |
| Append | `memory_append(block="project", content="...")` | New pattern discovered |
| Replace | `memory_replace(block="project", content="...")` | Audit/GC |
| Audit | Manual trigger | Every 10 tasks |

## Common Pitfalls

**Over-documenting**: Don't write obvious things.

**Under-documenting**: Don't skip important decisions.

**Stale content**: Regular audits prevent obsolete guidance.

**No examples**: Every rule needs a code example.

**Vague language**: Be specific and actionable.
