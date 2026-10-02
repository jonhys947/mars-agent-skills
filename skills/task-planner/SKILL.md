---
name: task-planner
description: Standards for creating implementation tasks (tasks.md). Use when breaking down features into actionable steps.
---

# Task Creation Standards

## Purpose

Ensure complete traceability by linking tasks to both requirements and design sections. This enables clear understanding of why each task exists and how to implement it.

## Task Granularity (The Rule of 3)

**CRITICAL CONSTRAINT:** No single implementation task should require modifying more than **3 files**.

*   **Why?** To prevent "Context Overflow" in Fullstack/System engineers.
*   **How to Break Down:**
    *   *Bad:* "Implement Authentication" (Touches DB, API, UI).
    *   *Good:*
        1.  "Define Auth Types" (1 file: `types.ts`)
        2.  "Create API Route" (1 file: `routes/auth.ts`)
        3.  "Create DB Model" (1 file: `models/user.ts`)
        4.  "Create Login Form" (1 file: `components/LoginForm.tsx`)

## Linking Rules

### Requirements Linking
**Format**: `_Requirements: X.Y, X.Z_`
- List requirement IDs from the requirements document.

### Design Linking
**Format**: `_Design: Section Name > Subsection Name_`
- Reference section headings from the design document.

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
