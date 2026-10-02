---
name: performance-go
description: Go-specific performance optimization techniques, profiling, and runtime tuning.
---

# Performance Optimization - Go

## Profiling Tools

### CPU Profiling

```go
import _ "net/http/pprof"

func main() {
    go func() {
        log.Println(http.ListenAndServe("localhost:6060", nil))
    }()
    // Your application code
}

// Access profiles at:
// http://localhost:6060/debug/pprof/
// http://localhost:6060/debug/pprof/profile?seconds=30
```

### Memory Profiling

```bash
# Heap profile
go tool pprof http://localhost:6060/debug/pprof/heap

# Allocation profile
go tool pprof http://localhost:6060/debug/pprof/allocs

# Analyze with web UI
go tool pprof -http=:8080 profile.pb.gz
```

### Benchmarking

```go
func BenchmarkMyFunction(b *testing.B) {
    for i := 0; i < b.N; i++ {
        MyFunction()
    }
}

// Run benchmarks
// go test -bench=. -benchmem
// -benchmem shows memory allocations
```

## Memory Optimization

### Avoid Allocations

```go
// Bad: Allocates on every call
func process(data []byte) string {
    return string(data) // Allocation!
}

// Good: Use bytes.Buffer or strings.Builder
func process(data []byte) string {
    var buf strings.Builder
    buf.Write(data)
    return buf.String()
}
```

### Preallocate Slices

```go
// Bad: Grows dynamically (multiple allocations)
var items []Item
for i := 0; i < 1000; i++ {
    items = append(items, Item{})
}

// Good: Preallocate capacity
items := make([]Item, 0, 1000)
for i := 0; i < 1000; i++ {
    items = append(items, Item{})
}
```

### Reuse Buffers (sync.Pool)

```go
var bufferPool = sync.Pool{
    New: func() interface{} {
        return new(bytes.Buffer)
    },
}

func process() {
    buf := bufferPool.Get().(*bytes.Buffer)
    defer func() {
        buf.Reset()
        bufferPool.Put(buf)
    }()
    
    // Use buf
}
```

### Pointer vs Value

```go
// Use pointers for large structs (> 64 bytes)
type LargeStruct struct {
    // Many fields...
}

func process(s *LargeStruct) { // Pointer avoids copy
    // ...
}

// Use values for small structs
type Point struct {
    X, Y int
}

func distance(p1, p2 Point) float64 { // Value is fine
    // ...
}
```

## Concurrency Optimization

### Goroutine Pooling

```go
// Bad: Unlimited goroutines
for _, item := range items {
    go process(item) // Can spawn millions!
}

// Good: Worker pool
const workers = 10
sem := make(chan struct{}, workers)

for _, item := range items {
    sem <- struct{}{} // Acquire
    go func(item Item) {
        defer func() { <-sem }() // Release
        process(item)
    }(item)
}

// Wait for all
for i := 0; i < workers; i++ {
    sem <- struct{}{}
}
```

### Channel Buffering

```go
// Bad: Unbuffered (blocks on every send)
ch := make(chan int)

// Good: Buffered (reduces blocking)
ch := make(chan int, 100)
```

### Context for Cancellation

```go
func process(ctx context.Context, data []Item) error {
    for _, item := range data {
        select {
        case <-ctx.Done():
            return ctx.Err() // Early exit
        default:
            if err := processItem(item); err != nil {
                return err
            }
        }
    }
    return nil
}
```

## String Optimization

### strings.Builder

```go
// Bad: String concatenation (O(n²) allocations)
var result string
for _, s := range items {
    result += s // Allocates new string each time!
}

// Good: strings.Builder (O(n) allocations)
var builder strings.Builder
for _, s := range items {
    builder.WriteString(s)
}
result := builder.String()
```

### Avoid []byte to string Conversions

```go
// Bad: Unnecessary conversion
func check(data []byte) bool {
    return strings.Contains(string(data), "pattern") // Allocation!
}

// Good: Use bytes package
func check(data []byte) bool {
    return bytes.Contains(data, []byte("pattern"))
}
```

## Map Optimization

### Preallocate Maps

```go
// Bad: Grows dynamically
m := make(map[string]int)
for i := 0; i < 1000; i++ {
    m[fmt.Sprintf("key%d", i)] = i
}

// Good: Preallocate
m := make(map[string]int, 1000)
for i := 0; i < 1000; i++ {
    m[fmt.Sprintf("key%d", i)] = i
}
```

### Avoid Map in Hot Path

```go
// Bad: Map lookup in tight loop
for i := 0; i < 1000000; i++ {
    value := config["key"] // Map lookup every iteration
    process(value)
}

// Good: Cache lookup result
value := config["key"]
for i := 0; i < 1000000; i++ {
    process(value)
}
```

## I/O Optimization

### Buffered I/O

```go
// Bad: Unbuffered writes
file, _ := os.Create("output.txt")
for _, line := range lines {
    file.WriteString(line) // System call per line!
}

// Good: Buffered writes
file, _ := os.Create("output.txt")
writer := bufio.NewWriter(file)
for _, line := range lines {
    writer.WriteString(line)
}
writer.Flush()
```

### Connection Pooling

```go
// Good: Reuse HTTP connections
client := &http.Client{
    Transport: &http.Transport{
        MaxIdleConns:        100,
        MaxIdleConnsPerHost: 10,
        IdleConnTimeout:     90 * time.Second,
    },
}
```

## JSON Optimization

### Use json.Decoder for Streams

```go
// Bad: Read entire body into memory
body, _ := io.ReadAll(resp.Body)
var data Data
json.Unmarshal(body, &data)

// Good: Stream decode
var data Data
json.NewDecoder(resp.Body).Decode(&data)
```

### Use easyjson or jsoniter

```go
// Standard library is slow for large payloads
// Consider: github.com/mailru/easyjson
// Or: github.com/json-iterator/go

//go:generate easyjson -all types.go

type User struct {
    ID    string `json:"id"`
    Email string `json:"email"`
}

// Generated methods: MarshalJSON, UnmarshalJSON
```

## Compiler Optimizations

### Inline Functions

```go
// Small functions are automatically inlined
func add(a, b int) int {
    return a + b
}

// Force inline (use sparingly)
//go:inline
func criticalPath() {
    // ...
}
```

### Escape Analysis

```go
// Bad: Escapes to heap
func create() *int {
    x := 42
    return &x // x escapes to heap
}

// Good: Stack allocation
func create() int {
    return 42 // Stays on stack
}

// Check with: go build -gcflags="-m"
```

## Runtime Tuning

### GOMAXPROCS

```go
import "runtime"

func init() {
    // Set to number of CPU cores (default since Go 1.5)
    runtime.GOMAXPROCS(runtime.NumCPU())
}
```

### Garbage Collection Tuning

```go
import "runtime/debug"

func init() {
    // Increase GC target percentage (default 100)
    // Higher = less frequent GC, more memory usage
    debug.SetGCPercent(200)
    
    // Set memory limit (Go 1.19+)
    debug.SetMemoryLimit(1 << 30) // 1GB
}
```

## Database Optimization

### Prepared Statements

```go
// Bad: Prepare on every query
for _, user := range users {
    db.Exec("INSERT INTO users (name) VALUES (?)", user.Name)
}

// Good: Prepare once, execute many
stmt, _ := db.Prepare("INSERT INTO users (name) VALUES (?)")
defer stmt.Close()
for _, user := range users {
    stmt.Exec(user.Name)
}
```

### Batch Operations

```go
// Bad: Individual inserts
for _, user := range users {
    db.Exec("INSERT INTO users (name) VALUES (?)", user.Name)
}

// Good: Batch insert
tx, _ := db.Begin()
stmt, _ := tx.Prepare("INSERT INTO users (name) VALUES (?)")
for _, user := range users {
    stmt.Exec(user.Name)
}
stmt.Close()
tx.Commit()
```

## Caching

### sync.Map for Concurrent Access

```go
// Good: Concurrent-safe map
var cache sync.Map

func get(key string) (interface{}, bool) {
    return cache.Load(key)
}

func set(key string, value interface{}) {
    cache.Store(key, value)
}
```

### LRU Cache

```go
import "github.com/hashicorp/golang-lru"

cache, _ := lru.New(1000) // Max 1000 items

cache.Add("key", value)
if val, ok := cache.Get("key"); ok {
    // Use val
}
```

## Profiling Checklist

1. **CPU Profile**: Find hot functions
   ```bash
   go tool pprof -http=:8080 cpu.prof
   ```

2. **Memory Profile**: Find allocations
   ```bash
   go tool pprof -http=:8080 -alloc_space mem.prof
   ```

3. **Goroutine Profile**: Find leaks
   ```bash
   curl http://localhost:6060/debug/pprof/goroutine
   ```

4. **Trace**: Visualize execution
   ```bash
   go test -trace=trace.out
   go tool trace trace.out
   ```

## Benchmarking Best Practices

```go
func BenchmarkProcess(b *testing.B) {
    // Setup (not timed)
    data := generateTestData()
    
    b.ResetTimer() // Reset timer after setup
    
    for i := 0; i < b.N; i++ {
        process(data)
    }
}

// Run with:
// go test -bench=. -benchmem -cpuprofile=cpu.prof
```

## Common Pitfalls

### Defer in Loops

```go
// Bad: Defers accumulate
for _, file := range files {
    f, _ := os.Open(file)
    defer f.Close() // Doesn't close until function returns!
}

// Good: Close immediately or use function
for _, file := range files {
    func() {
        f, _ := os.Open(file)
        defer f.Close()
        // Process file
    }()
}
```

### Range Copies Values

```go
// Bad: Copies entire struct
for _, item := range items { // item is a copy!
    item.Field = "new" // Doesn't modify original
}

// Good: Use index or pointer
for i := range items {
    items[i].Field = "new"
}
```

### Unnecessary Goroutines

```go
// Bad: Goroutine overhead for trivial work
for _, item := range items {
    go process(item) // Overhead > benefit for small items
}

// Good: Use goroutines for I/O-bound or CPU-intensive work
```
