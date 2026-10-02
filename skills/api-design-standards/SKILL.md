---
name: api-design-standards
description: REST API design conventions, versioning, error handling, and documentation standards.
---

# API Design Standards

## Core Principles

- **Consistency**: Predictable patterns across all endpoints
- **RESTful**: Follow REST conventions where applicable
- **Versioning**: Plan for evolution from day one
- **Documentation**: OpenAPI/Swagger for all endpoints
- **Security**: Authentication, authorization, rate limiting

## URL Structure

### Resource Naming

```
# Good: Plural nouns, hierarchical
GET    /api/v1/users
GET    /api/v1/users/{id}
GET    /api/v1/users/{id}/posts
POST   /api/v1/users/{id}/posts

# Bad: Verbs, inconsistent pluralization
GET    /api/v1/getUser
GET    /api/v1/user/{id}
POST   /api/v1/createPost
```

### HTTP Methods

- **GET**: Retrieve resource(s) - idempotent, cacheable
- **POST**: Create resource - not idempotent
- **PUT**: Replace entire resource - idempotent
- **PATCH**: Partial update - not idempotent
- **DELETE**: Remove resource - idempotent

### Query Parameters

```
# Filtering
GET /api/v1/users?status=active&role=admin

# Sorting
GET /api/v1/users?sort=created_at:desc

# Pagination
GET /api/v1/users?page=2&limit=20
GET /api/v1/users?offset=40&limit=20

# Field selection (sparse fieldsets)
GET /api/v1/users?fields=id,email,name

# Search
GET /api/v1/users?q=john
```

## Versioning Strategies

### URL Versioning (Recommended)

```
GET /api/v1/users
GET /api/v2/users
```

**Pros**: Clear, easy to route, visible in logs  
**Cons**: URL changes between versions

### Header Versioning

```
GET /api/users
Accept: application/vnd.myapi.v1+json
```

**Pros**: Clean URLs  
**Cons**: Less visible, harder to test

### Version Lifecycle

- **v1**: Current stable
- **v2**: New version (v1 deprecated but supported)
- **v1 EOL**: Announce 6-12 months before removal
- **Breaking changes**: Always require new major version

## Request/Response Format

### Request Body (POST/PUT/PATCH)

```json
POST /api/v1/users
Content-Type: application/json

{
  "email": "user@example.com",
  "name": "John Doe",
  "role": "admin"
}
```

### Success Response

```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "data": {
    "id": "usr_123",
    "email": "user@example.com",
    "name": "John Doe",
    "role": "admin",
    "created_at": "2024-02-04T10:00:00Z"
  }
}
```

### Collection Response

```json
HTTP/1.1 200 OK
Content-Type: application/json

{
  "data": [
    { "id": "usr_123", "name": "John" },
    { "id": "usr_124", "name": "Jane" }
  ],
  "meta": {
    "total": 150,
    "page": 1,
    "limit": 20,
    "pages": 8
  },
  "links": {
    "self": "/api/v1/users?page=1",
    "next": "/api/v1/users?page=2",
    "last": "/api/v1/users?page=8"
  }
}
```

## Error Handling

### Error Response Format

```json
HTTP/1.1 400 Bad Request
Content-Type: application/json

{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request parameters",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ],
    "request_id": "req_abc123"
  }
}
```

### HTTP Status Codes

**Success (2xx)**:
- `200 OK`: Successful GET, PUT, PATCH, DELETE
- `201 Created`: Successful POST (include `Location` header)
- `204 No Content`: Successful DELETE with no response body

**Client Errors (4xx)**:
- `400 Bad Request`: Invalid syntax, validation failure
- `401 Unauthorized`: Missing or invalid authentication
- `403 Forbidden`: Authenticated but not authorized
- `404 Not Found`: Resource doesn't exist
- `409 Conflict`: Resource conflict (duplicate, version mismatch)
- `422 Unprocessable Entity`: Semantic validation failure
- `429 Too Many Requests`: Rate limit exceeded

**Server Errors (5xx)**:
- `500 Internal Server Error`: Unexpected server error
- `502 Bad Gateway`: Upstream service failure
- `503 Service Unavailable`: Temporary unavailability
- `504 Gateway Timeout`: Upstream timeout

### Error Codes

Define application-specific error codes:

```typescript
enum ErrorCode {
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  RESOURCE_NOT_FOUND = 'RESOURCE_NOT_FOUND',
  DUPLICATE_RESOURCE = 'DUPLICATE_RESOURCE',
  UNAUTHORIZED = 'UNAUTHORIZED',
  FORBIDDEN = 'FORBIDDEN',
  RATE_LIMIT_EXCEEDED = 'RATE_LIMIT_EXCEEDED',
  INTERNAL_ERROR = 'INTERNAL_ERROR'
}
```

## Authentication & Authorization

### Bearer Token (Recommended)

```
GET /api/v1/users
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### API Key (For service-to-service)

```
GET /api/v1/users
X-API-Key: sk_live_abc123...
```

### Rate Limiting Headers

```
HTTP/1.1 200 OK
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1612137600
```

## Pagination

### Offset-Based (Simple)

```
GET /api/v1/users?offset=40&limit=20

Response:
{
  "data": [...],
  "meta": {
    "offset": 40,
    "limit": 20,
    "total": 150
  }
}
```

### Cursor-Based (Scalable)

```
GET /api/v1/users?cursor=eyJpZCI6MTIzfQ&limit=20

Response:
{
  "data": [...],
  "meta": {
    "next_cursor": "eyJpZCI6MTQzfQ",
    "has_more": true
  }
}
```

## Filtering & Sorting

### Filtering

```
# Simple equality
GET /api/v1/users?status=active

# Multiple values (OR)
GET /api/v1/users?status=active,pending

# Operators
GET /api/v1/users?created_at[gte]=2024-01-01&created_at[lt]=2024-02-01
```

### Sorting

```
# Single field
GET /api/v1/users?sort=created_at

# Descending
GET /api/v1/users?sort=-created_at

# Multiple fields
GET /api/v1/users?sort=role,-created_at
```

## Idempotency

### Idempotency Keys (POST)

```
POST /api/v1/payments
Idempotency-Key: key_abc123
Content-Type: application/json

{
  "amount": 1000,
  "currency": "usd"
}
```

Server stores key and returns same response for duplicate requests.

## Caching

### Cache Headers

```
# Cacheable response
HTTP/1.1 200 OK
Cache-Control: public, max-age=3600
ETag: "abc123"

# Conditional request
GET /api/v1/users/123
If-None-Match: "abc123"

# Not modified
HTTP/1.1 304 Not Modified
```

## Webhooks

### Webhook Payload

```json
POST https://customer.com/webhooks
Content-Type: application/json
X-Webhook-Signature: sha256=abc123...

{
  "event": "user.created",
  "data": {
    "id": "usr_123",
    "email": "user@example.com"
  },
  "timestamp": "2024-02-04T10:00:00Z"
}
```

### Signature Verification

```typescript
const signature = req.headers['x-webhook-signature'];
const payload = JSON.stringify(req.body);
const expected = crypto
  .createHmac('sha256', webhookSecret)
  .update(payload)
  .digest('hex');

if (signature !== `sha256=${expected}`) {
  throw new Error('Invalid signature');
}
```

## Documentation (OpenAPI)

```yaml
openapi: 3.0.0
info:
  title: My API
  version: 1.0.0
paths:
  /users:
    get:
      summary: List users
      parameters:
        - name: status
          in: query
          schema:
            type: string
            enum: [active, inactive]
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/User'
components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: string
        email:
          type: string
          format: email
```

## Best Practices

1. **Use nouns, not verbs** in URLs
2. **Version from day one** (even if v1)
3. **Return created resource** in POST responses
4. **Include request_id** in all responses for tracing
5. **Use ISO 8601** for timestamps
6. **Validate input** strictly (fail fast)
7. **Rate limit** all endpoints
8. **Log all requests** with correlation IDs
9. **Document everything** with OpenAPI
10. **Test with real clients** (Postman, curl)
