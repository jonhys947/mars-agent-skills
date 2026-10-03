---
name: testing-standards
description: Comprehensive testing standards including unit, integration, property-based, and E2E testing. Use when writing or reviewing tests.
---

# Testing Standards Skill

## Purpose

Establish consistent testing practices across all codebases. Ensure tests are reliable, maintainable, and provide meaningful coverage.

## Choosing Test Scope

```
        /\
       /E2E\         <- Use for critical end-to-end behavior
      /------\
     /Integration\   <- Use at important component boundaries
    /------------\
   /    Unit      \  <- Use for focused logic and edge cases
  /----------------\
```

This is a selection aid, not a quota. Choose tests from the behavior, failure modes, integration boundaries, and verification gates relevant to the task. Follow project-specific requirements when they exist.

## Test Tools and Dependencies

Prefer the test framework and utilities already used by the project. The libraries below are examples, not blanket approval to install them. Add a dependency only when the task and the project's dependency policy authorize it; otherwise use the existing toolchain or report the limitation.

### JavaScript/TypeScript
- `fast-check` - Property-based testing
- `@faker-js/faker` - Test data generation
- `vitest` - Unit testing framework
- `jest` - Unit testing framework
- `@testing-library/react` - React component testing
- `@testing-library/dom` - DOM testing utilities
- `playwright` - E2E testing
- `cypress` - E2E testing
- `msw` - API mocking

### Python
- `hypothesis` - Property-based testing
- `faker` - Test data generation
- `pytest` - Unit testing framework
- `pytest-cov` - Coverage reporting
- `pytest-mock` - Mocking utilities
- `responses` - HTTP mocking
- `freezegun` - Time mocking

### Go
- `github.com/stretchr/testify` - Testing toolkit
- `github.com/golang/mock` - Mocking framework
- `gopter` - Property-based testing
- `go-fuzz` - Fuzzing
- `httptest` - HTTP testing (stdlib)

## Unit Testing Standards

### Structure: Arrange-Act-Assert (AAA)

```javascript
test('calculateTotal adds item prices correctly', () => {
  // Arrange: Setup test data
  const items = [
    { price: 10.00, quantity: 2 },
    { price: 5.50, quantity: 1 }
  ];
  
  // Act: Execute the function
  const result = calculateTotal(items);
  
  // Assert: Verify the outcome
  expect(result).toBe(25.50);
});
```

### Naming Convention

**Format**: `[function/method] [scenario] [expected behavior]`

**Examples:**
- `calculateTotal with empty array returns zero`
- `validateEmail with invalid format returns false`
- `fetchUser with non-existent ID throws NotFoundError`

### Test Data

**Use fixed, hardcoded values:**
```javascript
// Good: Deterministic
const testUser = {
  id: 'user-123',
  email: 'test@example.com',
  createdAt: '2024-01-15T10:00:00Z'
};

// Bad: Non-deterministic
const testUser = {
  id: generateUUID(),
  email: faker.internet.email(),
  createdAt: new Date().toISOString()
};
```

**Exception**: Use generators for property-based tests only.

### Coverage and Risk

There is no universal line-coverage percentage. Follow explicit project gates or user requirements. Use coverage reports to find untested behavior, then prioritize concrete risks such as authorization boundaries, data loss, state transitions, input validation, and failure recovery. Do not treat a percentage alone as evidence that behavior is correct.

### What to Test

**DO test:**
- Public API functions and methods
- Business logic and calculations
- Error handling and edge cases
- Input validation
- State transitions

**DON'T test:**
- Private implementation details
- Third-party library internals
- Trivial getters/setters
- Framework code

## Property-Based Testing (PBT)

### When to Use PBT

**Consider PBT for:**
- Parsers, converters, serializers, and other transformations with broad input spaces
- Calculations and algorithms with precise invariants
- Security-sensitive logic when the property is meaningful and the existing tools support it

PBT is optional. A conventional example-based test may be clearer or sufficient; choose based on the risk and observable contract rather than the category alone.

### PBT Patterns

#### Round-Trip Property
```javascript
import fc from 'fast-check';

test('JSON serialization round-trip', () => {
  fc.assert(
    fc.property(fc.object(), (obj) => {
      const serialized = JSON.stringify(obj);
      const deserialized = JSON.parse(serialized);
      expect(deserialized).toEqual(obj);
    })
  );
});
```

#### Idempotence Property
```javascript
test('sorting is idempotent', () => {
  fc.assert(
    fc.property(fc.array(fc.integer()), (arr) => {
      const sorted1 = sort(arr);
      const sorted2 = sort(sorted1);
      expect(sorted2).toEqual(sorted1);
    })
  );
});
```

#### Invariant Property
```javascript
test('balance never goes negative', () => {
  fc.assert(
    fc.property(
      fc.float({ min: 0, max: 1000 }),
      fc.float({ min: 0, max: 100 }),
      (balance, withdrawal) => {
        const result = withdraw(balance, withdrawal);
        expect(result).toBeGreaterThanOrEqual(0);
      }
    )
  );
});
```

### PBT Best Practices

1. **Start simple**: Begin with basic properties
2. **Use shrinking**: Let the framework find minimal failing cases
3. **Set iteration count**: Use the project's configuration and runtime budget; preserve or report any relevant seed and failing case.
4. **Document properties**: Explain what invariant you're testing
5. **Combine with unit tests**: PBT complements, doesn't replace unit tests

## Integration Testing

### Scope

Test interactions between components:
- API endpoints with database
- Service-to-service communication
- External API integrations
- Message queue processing

### Setup/Teardown

```javascript
describe('User API Integration', () => {
  beforeAll(async () => {
    // Setup: Start test database
    await db.connect();
  });
  
  afterAll(async () => {
    // Teardown: Clean up
    await db.disconnect();
  });
  
  beforeEach(async () => {
    // Reset state before each test
    await db.clear();
  });
  
  test('POST /users creates user in database', async () => {
    const response = await api.post('/users', {
      email: 'test@example.com'
    });
    
    expect(response.status).toBe(201);
    
    const user = await db.users.findOne({ email: 'test@example.com' });
    expect(user).toBeDefined();
  });
});
```

### Test Isolation

- Each test should be independent
- Use transactions or cleanup between tests
- Don't rely on test execution order
- Mock external services (use `msw`, `nock`, etc.)

## E2E Testing

### When to Write E2E Tests

- Critical user journeys (login, checkout, signup)
- Cross-service workflows
- UI interactions with backend state
- Regression prevention for major bugs

### E2E Best Practices

1. **Keep them few**: E2E tests are slow and brittle
2. **Test happy paths**: Focus on critical flows
3. **Use page objects**: Encapsulate UI interactions
4. **Avoid flakiness**: Use proper waits, not sleeps
5. **Run in CI**: Catch integration issues early

### Example (Playwright)

```javascript
test('user can complete checkout', async ({ page }) => {
  // Navigate to product
  await page.goto('/products/widget-123');
  
  // Add to cart
  await page.click('[data-testid="add-to-cart"]');
  
  // Go to checkout
  await page.click('[data-testid="cart-icon"]');
  await page.click('[data-testid="checkout-button"]');
  
  // Fill payment info
  await page.fill('[data-testid="card-number"]', '4242424242424242');
  await page.fill('[data-testid="expiry"]', '12/25');
  await page.fill('[data-testid="cvc"]', '123');
  
  // Submit
  await page.click('[data-testid="submit-payment"]');
  
  // Verify success
  await expect(page.locator('[data-testid="order-confirmation"]')).toBeVisible();
});
```

## Test Organization

### File Structure

```
src/
  auth/
    auth.ts
    auth.test.ts          # Unit tests
    auth.integration.test.ts  # Integration tests
    auth.prop.test.ts     # Property-based tests
tests/
  e2e/
    checkout.spec.ts      # E2E tests
  fixtures/
    users.json            # Test data
  helpers/
    db.ts                 # Test utilities
```

### Naming Conventions

- Unit tests: `*.test.ts` or `*.spec.ts`
- Integration tests: `*.integration.test.ts`
- Property-based tests: `*.prop.test.ts`
- E2E tests: `*.e2e.test.ts` or `*.spec.ts` (in e2e folder)

## Mocking Standards

### When to Mock

**DO mock:**
- External APIs and services
- Database calls (in unit tests)
- Time-dependent functions
- Random number generators
- File system operations

**DON'T mock:**
- Internal business logic
- Simple utility functions
- The system under test

### Mock Patterns

**Dependency Injection:**
```typescript
// Good: Testable
class UserService {
  constructor(private db: Database) {}
  
  async getUser(id: string) {
    return this.db.users.findOne({ id });
  }
}

// Test
const mockDb = { users: { findOne: jest.fn() } };
const service = new UserService(mockDb);
```

**Interface Mocking:**
```go
// Good: Testable
type UserRepository interface {
  FindByID(id string) (*User, error)
}

type UserService struct {
  repo UserRepository
}

// Test
type MockRepo struct {
  mock.Mock
}

func (m *MockRepo) FindByID(id string) (*User, error) {
  args := m.Called(id)
  return args.Get(0).(*User), args.Error(1)
}
```

## Test Complexity

Keep tests direct enough that the assertion and failure are easy to understand. Split setup or scenarios when that improves readability, but do not apply universal complexity or line-count thresholds. A complicated test can indicate unclear test setup, production behavior, or both; inspect the specific cause.

## Continuous Integration

Use the repository's CI workflow and required gates. The following is an illustrative shape, not a required job matrix or command set:

```yaml
# Example: GitHub Actions
test:
  unit:
    runs-on: ubuntu-latest
    steps:
      - run: npm test -- --coverage
      - run: npm run test:lint
  
  integration:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
    steps:
      - run: npm run test:integration
  
  e2e:
    runs-on: ubuntu-latest
    steps:
      - run: npm run test:e2e
```

### Local Verification Order

Run focused checks first, then the broader project-defined gates that apply to the change. Do not claim a CI result unless it is confirmed for the relevant revision.

## Common Pitfalls

**Flaky tests**: Use proper waits, avoid race conditions, seed random data.

**Over-mocking**: Don't mock everything; test real integrations when possible.

**Testing implementation**: Test behavior, not internal structure.

**Ignoring failures**: Fix or remove failing tests immediately.

**No assertions**: Every test must have at least one assertion.

## Quick Reference

| Test Type | Speed | Scope | When to Use |
|-----------|-------|-------|-------------|
| Unit | Fast (ms) | Single function | Focused logic and edge cases where useful |
| Integration | Medium (seconds) | Multiple components | API/DB interactions |
| Property-Based | Medium (seconds) | Single function | Data transformation, math |
| E2E | Slow (minutes) | Full system | Critical user flows |

## Integration with Agents

Use this guidance in whichever roles the project defines. Tool or dependency installation, coverage gates, and test ownership follow the user's instructions and project policy; this skill does not grant installation authority.
