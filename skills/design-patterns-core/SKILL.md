---
name: design-patterns-core
description: Pattern selection guidance for architects. Use MCP servers for language-specific examples.
---

# Design Patterns Selection Guide

## When to Use Patterns

### Creational Patterns
Use when object creation logic becomes complex or needs flexibility.

| Pattern | Use When |
|---------|----------|
| **Factory Method** | Creating objects without specifying exact class; subclasses decide |
| **Abstract Factory** | Creating families of related objects without concrete classes |
| **Builder** | Constructing complex objects step-by-step; many optional parameters |
| **Prototype** | Cloning existing objects; creation is expensive |
| **Singleton** | Exactly one instance needed globally (use sparingly) |

### Structural Patterns
Use when composing objects into larger structures.

| Pattern | Use When |
|---------|----------|
| **Adapter** | Making incompatible interfaces work together |
| **Bridge** | Separating abstraction from implementation; both vary independently |
| **Composite** | Tree structures; treating individual objects and compositions uniformly |
| **Decorator** | Adding behavior dynamically without subclassing |
| **Facade** | Simplifying complex subsystem with unified interface |
| **Flyweight** | Many similar objects; sharing common state to save memory |
| **Proxy** | Controlling access; lazy loading, caching, access control |

### Behavioral Patterns
Use when defining communication between objects.

| Pattern | Use When |
|---------|----------|
| **Chain of Responsibility** | Multiple handlers; request passed until handled |
| **Command** | Encapsulating requests as objects; undo/redo, queuing |
| **Iterator** | Sequential access without exposing underlying structure |
| **Mediator** | Reducing chaotic dependencies; centralized communication |
| **Memento** | Saving/restoring object state; undo functionality |
| **Observer** | One-to-many notifications; event systems |
| **State** | Behavior changes based on internal state |
| **Strategy** | Interchangeable algorithms; runtime selection |
| **Template Method** | Algorithm skeleton; subclasses override specific steps |
| **Visitor** | Adding operations to objects without modifying them |

## Pattern Selection by Problem

| Problem | Recommended Pattern(s) |
|---------|----------------------|
| Object creation is complex | Builder, Factory Method |
| Need runtime algorithm selection | Strategy |
| Need to notify multiple objects | Observer |
| Incompatible interfaces | Adapter |
| Complex subsystem access | Facade |
| Adding features without subclassing | Decorator |
| Request handling chain | Chain of Responsibility |
| Undo/redo functionality | Command, Memento |
| State-dependent behavior | State |
| Tree/hierarchical structures | Composite |

## Design Doc Integration

When specifying patterns in design docs:
```markdown
## Design Patterns
- **[Pattern Name]** - [Component/area] - [Brief rationale]
```

Example:
```markdown
## Design Patterns
- **Strategy** - PaymentProcessor - Runtime selection of payment providers
- **Observer** - EventBus - Decoupled notification of order status changes
- **Factory Method** - ServiceFactory - Creating service instances with dependencies
```

## MCP Servers for Examples

Query language-specific MCP servers for implementation details:
- `go-design-patterns` - Go examples
- `ts-design-patterns` - TypeScript examples  
- `php-design-patterns` - PHP examples
