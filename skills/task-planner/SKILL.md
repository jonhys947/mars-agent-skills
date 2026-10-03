---
name: task-planner
description: Standards for creating implementation tasks (tasks.md). Use when breaking down features into actionable steps.
---

# Task Creation Standards

## Purpose

Keep tasks traceable to the user's requested outcome and to existing requirements or design documents when those sources are available. This helps explain why each task exists and how it fits the work without requiring artifacts the project does not use.

## Task Granularity

Size a task around one coherent outcome, its dependencies, ownership, and a way to verify it. There is no universal file-count limit: a behavior change may reasonably span the implementation, tests, and documentation that must change together.

Split work when parts can be implemented, reviewed, or verified independently, or when they need different owners or sequencing. Keep integration work explicit when separate tasks must come together. Avoid splitting a cohesive change into artificial one-file tasks or creating an implementation task that omits necessary cross-component behavior.

## Linking Rules

### Requirements Linking
**Format**: `_Requirements: X.Y, X.Z_`
- Use requirement IDs when the project has a requirements source. Do not invent IDs or require a requirements document that does not exist; otherwise link the task to the user's stated outcome or acceptance criteria.

### Design Linking
**Format**: `_Design: Section Name > Subsection Name_`
- Reference relevant headings when a design document exists. Do not invent a design artifact just to fill in a link.

## Task Structure

```markdown
- [ ] 1. [Top-level task]
  - [ ] 1.1 [Subtask]
    - Description of what to do
    - _Requirements: 1.1, 1.2_
    - _Design: Architecture > Component A_
```

## Special Cases

- **No Design Reference**: If a task (like setup) has no direct design section, omit the design link.
- **Multiple Design Areas**: List all relevant sections separated by commas.

## Best Practices

1. **Traceability**: Easily trace from task → requirement → design.
2. **Completeness**: Verify all requirements are covered.
3. **Context**: Understand the "why" and "how".
4. **Granularity**: Break tasks down into implementable chunks.
