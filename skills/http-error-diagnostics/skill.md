---
name: http-error-diagnostics
description: Common HTTP error codes and their typical root causes for faster debugging
---

# HTTP Error Diagnostics

Quick reference for diagnosing common HTTP errors. Check these known causes FIRST before deep investigation.

## Client Errors (4xx)

### 400 Bad Request
**Check first:**
1. Request body format (JSON syntax, required fields)
2. Content-Type header (application/json vs form-data)
3. Query parameter validation
4. Request size limits

**Common causes:**
- Malformed JSON
- Missing required fields
- Wrong Content-Type header
- Invalid query parameters

### 401 Unauthorized
**Check first:**
1. Auth token presence (Authorization header)
2. Token validity (expired, malformed)
3. Token format (Bearer, Basic, API key)
4. Auth middleware configuration

**Common causes:**
- Missing Authorization header
- Expired token
- Wrong token format
- Auth service down

### 403 Forbidden
**Check first:**
1. User permissions/roles
2. Resource ownership
3. IP whitelist/blacklist
4. CORS configuration

**Common causes:**
- Insufficient permissions
- User doesn't own resource
- IP blocked
- CORS policy violation

### 404 Not Found
**Check first:**
1. Route configuration (routes file, router setup)
2. URL path (typos, case sensitivity)
3. File paths (static files, templates)
4. API endpoint registration

**Common causes:**
- Route not registered
- Typo in URL
- File doesn't exist
- Wrong HTTP method

### 405 Method Not Allowed
**Check first:**
1. HTTP method (GET vs POST vs PUT vs DELETE)
2. Route method restrictions
3. CORS preflight handling

**Common causes:**
- Using GET instead of POST
- Route only accepts specific methods
- Missing OPTIONS handler for CORS

### 409 Conflict
**Check first:**
1. Unique constraints (database)
2. Concurrent modification checks
3. Resource state validation

**Common causes:**
- Duplicate key violation
- Resource already exists
- Optimistic locking failure

### 413 Payload Too Large
**Check first:**
1. Request body size limits (server config)
2. File upload limits
3. Reverse proxy limits (nginx, apache)

**Common causes:**
- Server body size limit too low
- File too large for upload
- Proxy buffer size exceeded

### 422 Unprocessable Entity
**Check first:**
1. Validation rules (schema validation)
2. Business logic constraints
3. Data type mismatches

**Common causes:**
- Failed validation
- Invalid data format
- Business rule violation

### 429 Rate Limit Exceeded ⚠️ COMMON
**Check first:**
1. **Rate limit configuration** (limits, burst, window)
2. Rate limit headers in response
3. Client request frequency
4. Rate limit key (IP, user, API key)

**Common causes:**
- Rate limit too low (most common!)
- Client making too many requests
- Rate limit not configured
- Wrong rate limit key

**Debugging steps:**
1. Check rate limit config file FIRST
2. Check response headers (X-RateLimit-*)
3. Check client request logs
4. Only then check middleware/code

## Server Errors (5xx)

### 500 Internal Server Error
**Check first:**
1. **Server logs** (stack trace, error message)
2. Recent code changes (git log)
3. Environment variables
4. Database connection

**Common causes:**
- Unhandled exception
- Missing environment variable
- Database connection failed
- Null pointer/undefined error

**Debugging steps:**
1. Read logs for stack trace FIRST
2. Check recent commits
3. Verify environment config
4. Check external service status

### 502 Bad Gateway
**Check first:**
1. Upstream service status (is it running?)
2. Service connection config (host, port)
3. Network connectivity
4. Reverse proxy configuration

**Common causes:**
- Upstream service down
- Wrong upstream address
- Network issue
- Proxy timeout

### 503 Service Unavailable
**Check first:**
1. Service health check
2. Resource exhaustion (CPU, memory, connections)
3. Deployment in progress
4. Circuit breaker state

**Common causes:**
- Service overloaded
- Out of memory
- Too many connections
- Intentional maintenance mode

### 504 Gateway Timeout
**Check first:**
1. Upstream service response time
2. Timeout configuration (proxy, server)
3. Long-running operations
4. Database query performance

**Common causes:**
- Slow upstream service
- Timeout too short
- Slow database query
- Blocking operation

## General Debugging Strategy

### For ANY HTTP error:

1. **Read the error message** - It's usually accurate
2. **Check configuration first** - Most errors are config, not code
3. **Check logs** - Stack traces tell you exactly what failed
4. **Check recent changes** - What changed since it last worked?
5. **Check external dependencies** - Database, APIs, services
6. **Then investigate code** - Only after ruling out config/environment

### Priority Order:

1. Configuration (env vars, config files, limits)
2. Logs (stack traces, error messages)
3. Recent changes (git log, deployments)
4. External services (database, APIs)
5. Code logic (only after above are ruled out)

## Common Patterns

**"It worked yesterday":**
- Check recent deployments
- Check environment changes
- Check external service changes

**"It works locally but not in production":**
- Check environment variables
- Check service URLs/ports
- Check permissions/access

**"Intermittent failures":**
- Check rate limits
- Check resource exhaustion
- Check concurrent access
- Check external service reliability

**"Same error repeatedly":**
- Trust the error message
- Focus on that specific error
- Don't investigate unrelated code

## Usage in Debugging

**When you see an HTTP error:**

1. Load this skill: `skill("http-error-diagnostics")`
2. Find the error code in this guide
3. Check the "Check first" items IN ORDER
4. Follow the debugging steps
5. Only investigate code if config/logs don't reveal issue

**Example:**

```
Error: 429 Rate Limit Exceeded

1. Check rate limit config → Found: burst=1 (too low!)
2. Fix: Set burst=10
3. Test: Success

Time: 5 minutes (instead of 40 minutes investigating auth)
```

## Anti-Patterns to Avoid

❌ Investigating code before checking config
❌ Ignoring explicit error messages
❌ Assuming complex causes for simple errors
❌ Reading entire files instead of logs
❌ Testing all hypotheses instead of most likely

✅ Check config first
✅ Trust error messages
✅ Prefer simple explanations
✅ Read logs for stack traces
✅ Test top 2 most likely causes
