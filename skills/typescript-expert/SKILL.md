---
name: typescript-expert
description: Expert guidance on TypeScript development, type safety, and modern patterns. Use for any TypeScript-related tasks.
---

# TypeScript Expert Skill

## Core Principles

- **Type Safety First**: Leverage TypeScript's type system fully - avoid `any`, use strict mode
- **Explicit Over Implicit**: Prefer explicit type annotations for public APIs
- **Composition Over Inheritance**: Use interfaces and type composition
- **Immutability**: Prefer `const`, `readonly`, and immutable patterns
- **Functional Patterns**: Leverage map/filter/reduce, avoid mutations

## Type System Best Practices

### Interface vs Type

**Use `interface` for:**
- Object shapes that may be extended
- Public APIs
- Class contracts

**Use `type` for:**
- Unions and intersections
- Mapped types
- Utility type compositions
- Primitive aliases

```typescript
// Good: Interface for extensible objects
interface User {
  id: string;
  email: string;
}

interface AdminUser extends User {
  permissions: string[];
}

// Good: Type for unions
type Status = 'pending' | 'active' | 'inactive';
type Result<T> = { success: true; data: T } | { success: false; error: string };
```

### Avoid `any`

```typescript
// Bad
function process(data: any) { }

// Good: Use generics
function process<T>(data: T): T { }

// Good: Use unknown for truly unknown types
function parse(json: string): unknown {
  return JSON.parse(json);
}
```

### Discriminated Unions

```typescript
type ApiResponse<T> =
  | { status: 'success'; data: T }
  | { status: 'error'; error: string }
  | { status: 'loading' };

function handle<T>(response: ApiResponse<T>) {
  switch (response.status) {
    case 'success':
      return response.data; // TypeScript knows data exists
    case 'error':
      throw new Error(response.error);
    case 'loading':
      return null;
  }
}
```

## Async Patterns

### Promise Handling

```typescript
// Good: Explicit error handling
async function fetchUser(id: string): Promise<User> {
  try {
    const response = await fetch(`/api/users/${id}`);
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    throw new Error(`Failed to fetch user: ${error}`);
  }
}

// Good: Result type pattern
type AsyncResult<T> = Promise<Result<T>>;

async function safeGetUser(id: string): AsyncResult<User> {
  try {
    const user = await fetchUser(id);
    return { success: true, data: user };
  } catch (error) {
    return { success: false, error: String(error) };
  }
}
```

### Concurrent Operations

```typescript
// Good: Parallel execution
const [users, posts, comments] = await Promise.all([
  fetchUsers(),
  fetchPosts(),
  fetchComments()
]);

// Good: Race conditions
const result = await Promise.race([
  fetchData(),
  timeout(5000)
]);
```

## Utility Types

Leverage built-in utility types:

```typescript
// Partial - make all properties optional
type PartialUser = Partial<User>;

// Required - make all properties required
type RequiredConfig = Required<Config>;

// Pick - select specific properties
type UserPreview = Pick<User, 'id' | 'email'>;

// Omit - exclude specific properties
type UserWithoutPassword = Omit<User, 'password'>;

// Record - create object type with specific keys
type UserMap = Record<string, User>;

// ReturnType - extract function return type
type FetchResult = ReturnType<typeof fetchUser>;
```

## Module Organization

```typescript
// Good: Barrel exports for clean imports
// src/types/index.ts
export type { User, AdminUser } from './user';
export type { Post, Comment } from './content';

// Good: Namespace for related types
export namespace API {
  export type Request<T> = { body: T; headers: Record<string, string> };
  export type Response<T> = { data: T; status: number };
}
```

## Type Guards

```typescript
// Good: Type predicate
function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'email' in value
  );
}

// Good: Assertion function
function assertUser(value: unknown): asserts value is User {
  if (!isUser(value)) {
    throw new Error('Not a valid user');
  }
}
```

## Generics Best Practices

```typescript
// Good: Constrained generics
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

// Good: Default type parameters
function createArray<T = string>(length: number, value: T): T[] {
  return Array(length).fill(value);
}

// Good: Generic constraints
interface HasId {
  id: string;
}

function findById<T extends HasId>(items: T[], id: string): T | undefined {
  return items.find(item => item.id === id);
}
```

## Configuration

### tsconfig.json Strict Mode

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "exactOptionalPropertyTypes": true
  }
}
```

## Common Pitfalls

### Avoid Type Assertions

```typescript
// Bad: Type assertion bypasses safety
const user = data as User;

// Good: Validate and narrow
if (isUser(data)) {
  const user = data; // Type is narrowed
}
```

### Avoid Non-Null Assertions

```typescript
// Bad: Assumes value exists
const name = user!.name;

// Good: Handle null case
const name = user?.name ?? 'Unknown';
```

### Avoid Enums (Prefer Union Types)

```typescript
// Bad: Enums have runtime overhead
enum Status {
  Active,
  Inactive
}

// Good: Union type (zero runtime cost)
type Status = 'active' | 'inactive';
```

## Testing with TypeScript

```typescript
// Good: Type-safe test helpers
function createMockUser(overrides?: Partial<User>): User {
  return {
    id: 'test-id',
    email: 'test@example.com',
    ...overrides
  };
}

// Good: Type-safe assertions
import { expectTypeOf } from 'vitest';

expectTypeOf(fetchUser).toBeFunction();
expectTypeOf(fetchUser).returns.resolves.toMatchTypeOf<User>();
```

## Design Patterns

Use the `design-patterns-core` skill for pattern selection, then implement with TypeScript's type system:

- **Factory**: Use generic factory functions
- **Builder**: Use method chaining with `this` return type
- **Strategy**: Use discriminated unions or function types
- **Observer**: Use typed event emitters or RxJS
- **Decorator**: Use higher-order functions with proper typing
