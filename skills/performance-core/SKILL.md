---
name: performance-core
description: Universal performance optimization principles applicable across all languages and platforms.
---

# Performance Optimization - Core Principles

## Measurement First

**Rule**: Never optimize without measuring. Premature optimization is the root of all evil.

### Profiling Tools
- **CPU profiling**: Identify hot paths
- **Memory profiling**: Find leaks and excessive allocations
- **Network profiling**: Trace API calls and latency
- **Database profiling**: Query execution time

### Key Metrics
- **Latency**: p50, p95, p99 response times
- **Throughput**: Requests per second
- **Resource usage**: CPU, memory, disk I/O
- **Error rate**: Failed requests percentage

## Algorithmic Complexity

### Time Complexity

```
O(1)       - Constant: Hash table lookup
O(log n)   - Logarithmic: Binary search
O(n)       - Linear: Array iteration
O(n log n) - Linearithmic: Efficient sorting
O(n²)      - Quadratic: Nested loops (avoid!)
O(2ⁿ)      - Exponential: Recursive fibonacci (avoid!)
```

**Rule**: Aim for O(n log n) or better for operations on large datasets.

### Space Complexity

Trade memory for speed when appropriate:
- **Caching**: Store computed results
- **Indexing**: Pre-compute lookup structures
- **Memoization**: Cache function results

## Caching Strategies

### Cache Levels

1. **In-memory cache** (fastest): Redis, Memcached
2. **Application cache**: LRU cache in process
3. **HTTP cache**: CDN, browser cache
4. **Database cache**: Query result cache

### Cache Invalidation

```
Write-through: Update cache on write
Write-behind: Async cache update
Cache-aside: Load on miss, update on write
TTL: Time-based expiration
```

### Cache Key Design

```
# Good: Hierarchical, versioned
user:123:profile:v2
posts:user:123:page:1:v1

# Bad: Ambiguous
user_123
posts_page_1
```

## Database Optimization

### Query Optimization
- **Index frequently queried columns**
- **Avoid N+1 queries** (use joins or batch loading)
- **Use pagination** for large result sets
- **Limit SELECT columns** (avoid SELECT *)
- **Use EXPLAIN** to analyze query plans

### Connection Pooling
- Reuse database connections
- Configure pool size based on load
- Monitor pool utilization

### Read Replicas
- Route reads to replicas
- Route writes to primary
- Handle replication lag

## Network Optimization

### Reduce Round Trips
- **Batch requests**: Combine multiple API calls
- **GraphQL**: Request exactly what you need
- **HTTP/2**: Multiplexing, server push
- **WebSockets**: Persistent connections

### Compression
- **gzip/brotli**: Compress text responses
- **Image optimization**: WebP, AVIF formats
- **Minification**: Remove whitespace from JS/CSS

### CDN Usage
- Serve static assets from CDN
- Edge caching for dynamic content
- Geographic distribution

## Concurrency & Parallelism

### Concurrency Patterns
- **Thread pools**: Limit concurrent operations
- **Worker queues**: Background job processing
- **Rate limiting**: Prevent resource exhaustion
- **Circuit breakers**: Fail fast on errors

### Async Operations
- **Non-blocking I/O**: Don't wait for I/O
- **Event loops**: Handle multiple operations
- **Promises/Futures**: Compose async operations

## Memory Management

### Avoid Memory Leaks
- **Release resources**: Close connections, files
- **Clear references**: Remove event listeners
- **Weak references**: For caches
- **Monitor heap**: Track memory growth

### Reduce Allocations
- **Object pooling**: Reuse objects
- **String builders**: Avoid concatenation
- **Preallocate**: Size collections upfront

## Lazy Loading

### Code Splitting
- Load modules on demand
- Route-based splitting
- Component-based splitting

### Data Loading
- Infinite scroll vs pagination
- Virtual scrolling for long lists
- Image lazy loading

## Batching & Debouncing

### Batching
```
# Instead of 100 individual requests
for item in items:
  api.update(item)

# Batch into single request
api.batch_update(items)
```

### Debouncing
```
# Delay execution until input stops
search_input.on_change(debounce(search, 300ms))
```

### Throttling
```
# Limit execution frequency
scroll.on_event(throttle(update_position, 100ms))
```

## Monitoring & Observability

### Metrics to Track
- **Response time**: p50, p95, p99
- **Error rate**: 4xx, 5xx responses
- **Throughput**: Requests per second
- **Resource usage**: CPU, memory, disk

### Distributed Tracing
- Trace requests across services
- Identify bottlenecks
- Measure service dependencies

### Logging
- Structured logging (JSON)
- Log levels (debug, info, warn, error)
- Correlation IDs for request tracking

## Load Testing

### Test Scenarios
- **Baseline**: Normal traffic
- **Peak load**: Expected maximum
- **Stress test**: Beyond capacity
- **Soak test**: Sustained load over time

### Tools
- Apache JMeter
- k6
- Gatling
- Locust

## Common Pitfalls

### Premature Optimization
- Measure first, optimize second
- Focus on bottlenecks, not micro-optimizations

### Over-Caching
- Cache invalidation is hard
- Stale data can cause bugs
- Memory overhead

### Ignoring Network Latency
- Network is often the bottleneck
- Reduce round trips
- Use compression

### Not Monitoring Production
- Synthetic tests don't match real usage
- Monitor real user metrics
- Set up alerts for anomalies

## Optimization Checklist

1. **Profile** to identify bottlenecks
2. **Measure** baseline performance
3. **Optimize** the slowest path first
4. **Measure** again to verify improvement
5. **Monitor** in production
6. **Iterate** based on real data

## Performance Budget

Set targets and enforce them:
- **Page load**: < 2 seconds
- **API response**: < 200ms (p95)
- **Database query**: < 50ms (p95)
- **Bundle size**: < 200KB (gzipped)

Use CI/CD to fail builds that exceed budget.
