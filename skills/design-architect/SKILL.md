---
name: design-architect
description: Standards for creating technical design documents (design.md). Use when creating or reviewing system designs.
---

# Design Document Standards

## Purpose

Design documents provide the technical blueprint for implementing requirements. They should be comprehensive, well-organized, and easy to navigate.

## Structure

### Table of Contents
Place after Overview.
```markdown
## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Components and Interfaces](#components-and-interfaces)
- [Data Models](#data-models)
...
```

### Visual Diagrams
Use **Mermaid** for diagrams.
- **Flowcharts**: Process flows.
- **Sequence Diagrams**: Component interactions.
- **Class Diagrams**: Data models.

```mermaid
flowchart TD
    A[Start] --> B{Decision?}
```

### External References
Create a section for tools, libraries, and specs.

```markdown
## External References
### Tools and Libraries
- **Actionlint**: [Link](...)
```

## Content Guidelines

### Tables
Use tables for structured info (inputs, outputs, config).

### Code Examples
Include examples for config files, API usage, and data structures. Specify the language.

### Components
For each component, define:
- **Purpose**
- **Inputs/Outputs**
- **Responsibilities**
- **Interactions**

## Best Practices

- **Context-First**: Before designing, Query `project-knowledge` to understand existing patterns.
- **Contract-First**: The FIRST deliverable of any design must be the **Interface Definition** (e.g., `types.ts`, `interfaces.go`). This allows parallel work.
- **Clarity**: Be precise about how the system works.
- **Traceability**: Reference which requirements are satisfied by which design element.
- **Completeness**: Cover error handling, validation, security, and performance.
