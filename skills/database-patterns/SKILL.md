---
name: database-patterns
description: Database design, query optimization, migration strategies, and ORM best practices.
---

# Database Patterns

## Core Principles

- **Normalization**: Reduce redundancy (3NF minimum)
- **Denormalization**: Strategic duplication for performance
- **Indexing**: Query patterns drive index design
- **Migrations**: Version-controlled, reversible schema changes
- **Transactions**: ACID guarantees for critical operations

## Schema Design

### Naming Conventions

```sql
-- Tables: plural, snake_case
users
blog_posts
order_items

-- Columns: singular, snake_case
id
user_id
created_at
updated_at

-- Indexes: descriptive
idx_users_email
idx_posts_user_id_created_at

-- Foreign keys: descriptive
fk_posts_user_id
```

### Primary Keys

```sql
-- Good: UUID for distributed systems
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Good: Auto-increment for single-instance
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### Foreign Keys

```sql
-- Good: Enforce referential integrity
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Index foreign keys for join performance
CREATE INDEX idx_posts_user_id ON posts(user_id);
```

### Timestamps

```sql
-- Good: Track creation and updates
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Trigger to auto-update updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

## Indexing Strategies

### Single Column Index

```sql
-- Good: Frequently queried columns
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_posts_status ON posts(status);
```

### Composite Index

```sql
-- Good: Multi-column queries (order matters!)
CREATE INDEX idx_posts_user_id_created_at ON posts(user_id, created_at DESC);

-- Supports:
-- WHERE user_id = ? ORDER BY created_at DESC
-- WHERE user_id = ?

-- Does NOT support:
-- WHERE created_at > ?
```

### Partial Index

```sql
-- Good: Index subset of rows
CREATE INDEX idx_posts_published ON posts(created_at)
  WHERE status = 'published';
```

### Covering Index

```sql
-- Good: Include columns to avoid table lookup
CREATE INDEX idx_users_email_name ON users(email) INCLUDE (name);

-- Query can be satisfied entirely from index
SELECT name FROM users WHERE email = 'user@example.com';
```

## Query Optimization

### N+1 Query Problem

```typescript
// Bad: N+1 queries
const users = await db.query('SELECT * FROM users');
for (const user of users) {
  user.posts = await db.query('SELECT * FROM posts WHERE user_id = ?', [user.id]);
}

// Good: Single query with JOIN
const users = await db.query(`
  SELECT 
    u.*,
    json_agg(p.*) as posts
  FROM users u
  LEFT JOIN posts p ON p.user_id = u.id
  GROUP BY u.id
`);

// Good: Separate queries with IN clause
const users = await db.query('SELECT * FROM users');
const userIds = users.map(u => u.id);
const posts = await db.query('SELECT * FROM posts WHERE user_id = ANY(?)', [userIds]);
// Group posts by user_id in application
```

### Pagination

```sql
-- Bad: OFFSET with large values (scans all skipped rows)
SELECT * FROM posts ORDER BY created_at DESC LIMIT 20 OFFSET 10000;

-- Good: Cursor-based (keyset pagination)
SELECT * FROM posts 
WHERE created_at < ?
ORDER BY created_at DESC 
LIMIT 20;
```

### Aggregations

```sql
-- Good: Use indexes for aggregations
CREATE INDEX idx_orders_user_id_total ON orders(user_id, total);

SELECT user_id, SUM(total) 
FROM orders 
GROUP BY user_id;
```

### EXPLAIN Analysis

```sql
-- Always analyze slow queries
EXPLAIN ANALYZE
SELECT * FROM posts 
WHERE user_id = 'abc' 
ORDER BY created_at DESC 
LIMIT 20;

-- Look for:
-- - Seq Scan (bad for large tables)
-- - Index Scan (good)
-- - High cost estimates
```

## Transactions

### ACID Guarantees

```typescript
// Good: Wrap related operations in transaction
await db.transaction(async (trx) => {
  const order = await trx('orders').insert({
    user_id: userId,
    total: 100
  }).returning('*');

  await trx('order_items').insert([
    { order_id: order.id, product_id: 'p1', quantity: 2 },
    { order_id: order.id, product_id: 'p2', quantity: 1 }
  ]);

  await trx('users').where({ id: userId }).decrement('balance', 100);
});
```

### Isolation Levels

```sql
-- Read Committed (default, usually sufficient)
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Serializable (strictest, prevents all anomalies)
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

### Optimistic Locking

```sql
-- Good: Version column for concurrent updates
CREATE TABLE products (
  id UUID PRIMARY KEY,
  name VARCHAR(255),
  stock INT,
  version INT NOT NULL DEFAULT 1
);

-- Update with version check
UPDATE products 
SET stock = stock - 1, version = version + 1
WHERE id = ? AND version = ?;

-- If affected rows = 0, version conflict occurred
```

## Migrations

### Migration Structure

```typescript
// Good: Up and down migrations
export async function up(db: Database) {
  await db.schema.createTable('users', (table) => {
    table.uuid('id').primary().defaultTo(db.raw('gen_random_uuid()'));
    table.string('email', 255).notNullable().unique();
    table.timestamp('created_at').notNullable().defaultTo(db.fn.now());
    table.timestamp('updated_at').notNullable().defaultTo(db.fn.now());
  });

  await db.schema.raw(`
    CREATE INDEX idx_users_email ON users(email)
  `);
}

export async function down(db: Database) {
  await db.schema.dropTable('users');
}
```

### Migration Best Practices

1. **Never modify existing migrations** - create new ones
2. **Test rollback** - ensure `down()` works
3. **Avoid data migrations in schema migrations** - separate concerns
4. **Use transactions** - all-or-nothing
5. **Add indexes concurrently** (PostgreSQL):
   ```sql
   CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
   ```

### Zero-Downtime Migrations

```sql
-- Step 1: Add new column (nullable)
ALTER TABLE users ADD COLUMN new_email VARCHAR(255);

-- Step 2: Backfill data (in batches)
UPDATE users SET new_email = email WHERE new_email IS NULL LIMIT 1000;

-- Step 3: Make non-nullable
ALTER TABLE users ALTER COLUMN new_email SET NOT NULL;

-- Step 4: Drop old column
ALTER TABLE users DROP COLUMN email;

-- Step 5: Rename new column
ALTER TABLE users RENAME COLUMN new_email TO email;
```

## ORM Best Practices

### Query Builder (Knex, Kysely)

```typescript
// Good: Type-safe query builder
const users = await db
  .selectFrom('users')
  .select(['id', 'email', 'name'])
  .where('status', '=', 'active')
  .orderBy('created_at', 'desc')
  .limit(20)
  .execute();
```

### Raw Queries (When Needed)

```typescript
// Good: Use raw for complex queries
const result = await db.raw(`
  WITH user_stats AS (
    SELECT 
      user_id,
      COUNT(*) as post_count,
      MAX(created_at) as last_post
    FROM posts
    GROUP BY user_id
  )
  SELECT u.*, us.post_count, us.last_post
  FROM users u
  LEFT JOIN user_stats us ON us.user_id = u.id
  WHERE u.status = ?
`, ['active']);
```

### Connection Pooling

```typescript
// Good: Configure pool size
const pool = new Pool({
  host: 'localhost',
  database: 'mydb',
  max: 20,              // Max connections
  min: 5,               // Min idle connections
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000
});
```

## Denormalization Patterns

### Computed Columns

```sql
-- Good: Store frequently accessed aggregates
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255),
  post_count INT NOT NULL DEFAULT 0
);

-- Update via trigger
CREATE TRIGGER update_user_post_count
  AFTER INSERT OR DELETE ON posts
  FOR EACH ROW
  EXECUTE FUNCTION update_user_post_count();
```

### Materialized Views

```sql
-- Good: Pre-compute expensive queries
CREATE MATERIALIZED VIEW user_stats AS
SELECT 
  u.id,
  u.email,
  COUNT(p.id) as post_count,
  MAX(p.created_at) as last_post
FROM users u
LEFT JOIN posts p ON p.user_id = u.id
GROUP BY u.id, u.email;

-- Refresh periodically
REFRESH MATERIALIZED VIEW CONCURRENTLY user_stats;
```

## Soft Deletes

```sql
-- Good: Add deleted_at column
CREATE TABLE posts (
  id UUID PRIMARY KEY,
  title VARCHAR(255),
  deleted_at TIMESTAMP
);

-- Query active records
SELECT * FROM posts WHERE deleted_at IS NULL;

-- Index for performance
CREATE INDEX idx_posts_deleted_at ON posts(deleted_at) WHERE deleted_at IS NULL;
```

## Full-Text Search

```sql
-- PostgreSQL: tsvector for full-text search
ALTER TABLE posts ADD COLUMN search_vector tsvector;

CREATE INDEX idx_posts_search ON posts USING GIN(search_vector);

-- Update search vector
UPDATE posts SET search_vector = 
  to_tsvector('english', title || ' ' || body);

-- Search
SELECT * FROM posts 
WHERE search_vector @@ to_tsquery('english', 'database & optimization');
```

## Common Pitfalls

### Avoid SELECT *

```sql
-- Bad: Fetches unnecessary data
SELECT * FROM users;

-- Good: Select only needed columns
SELECT id, email, name FROM users;
```

### Avoid OR in WHERE

```sql
-- Bad: Can't use indexes efficiently
SELECT * FROM posts WHERE user_id = ? OR status = ?;

-- Good: Use UNION or separate queries
SELECT * FROM posts WHERE user_id = ?
UNION
SELECT * FROM posts WHERE status = ?;
```

### Avoid Functions on Indexed Columns

```sql
-- Bad: Can't use index
SELECT * FROM users WHERE LOWER(email) = 'user@example.com';

-- Good: Store lowercase, or use functional index
CREATE INDEX idx_users_email_lower ON users(LOWER(email));
```

## Monitoring

Track these metrics:
- Query execution time (p50, p95, p99)
- Connection pool utilization
- Cache hit ratio
- Index usage
- Table bloat
- Lock contention

Use `pg_stat_statements` (PostgreSQL) or equivalent for query analysis.
