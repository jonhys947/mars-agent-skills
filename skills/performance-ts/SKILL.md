---
name: performance-ts
description: TypeScript/JavaScript performance optimization, bundle size, runtime performance, and React optimization.
---

# Performance Optimization - TypeScript/JavaScript

## Profiling Tools

### Chrome DevTools

```javascript
// CPU profiling
console.profile('myOperation');
expensiveOperation();
console.profileEnd('myOperation');

// Memory profiling
// DevTools > Memory > Take heap snapshot

// Performance timeline
// DevTools > Performance > Record
```

### Node.js Profiling

```bash
# CPU profile
node --prof app.js
node --prof-process isolate-*.log > processed.txt

# Heap snapshot
node --inspect app.js
# Chrome DevTools > Memory > Take snapshot

# Trace events
node --trace-events-enabled app.js
```

### Benchmarking

```typescript
import { performance } from 'perf_hooks';

const start = performance.now();
expensiveOperation();
const end = performance.now();
console.log(`Took ${end - start}ms`);

// Or use benchmark.js
import Benchmark from 'benchmark';

const suite = new Benchmark.Suite();
suite
  .add('Method A', () => methodA())
  .add('Method B', () => methodB())
  .on('cycle', (event: any) => console.log(String(event.target)))
  .run();
```

## Bundle Optimization

### Code Splitting

```typescript
// Route-based splitting
const Dashboard = lazy(() => import('./Dashboard'));
const Settings = lazy(() => import('./Settings'));

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Suspense>
  );
}
```

### Tree Shaking

```typescript
// Bad: Imports entire library
import _ from 'lodash';
_.debounce(fn, 300);

// Good: Import only what you need
import debounce from 'lodash/debounce';
debounce(fn, 300);

// Or use lodash-es for better tree shaking
import { debounce } from 'lodash-es';
```

### Dynamic Imports

```typescript
// Load on demand
async function loadChart() {
  const { Chart } = await import('chart.js');
  return new Chart(ctx, config);
}

// Conditional loading
if (user.isPremium) {
  const { PremiumFeature } = await import('./PremiumFeature');
  render(<PremiumFeature />);
}
```

### Bundle Analysis

```bash
# Webpack Bundle Analyzer
npm install --save-dev webpack-bundle-analyzer

# Add to webpack config
const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin;

module.exports = {
  plugins: [
    new BundleAnalyzerPlugin()
  ]
};

# Vite
npm install --save-dev rollup-plugin-visualizer
```

## Runtime Performance

### Avoid Unnecessary Re-renders (React)

```typescript
// Bad: Creates new object every render
<Component style={{ margin: 10 }} />

// Good: Memoize
const style = useMemo(() => ({ margin: 10 }), []);
<Component style={style} />

// Bad: Inline function
<button onClick={() => handleClick(id)}>Click</button>

// Good: useCallback
const handleClick = useCallback(() => {
  doSomething(id);
}, [id]);
<button onClick={handleClick}>Click</button>
```

### Virtualization

```typescript
// Bad: Render 10,000 items
{items.map(item => <Item key={item.id} {...item} />)}

// Good: Virtualize with react-window
import { FixedSizeList } from 'react-window';

<FixedSizeList
  height={600}
  itemCount={items.length}
  itemSize={50}
  width="100%"
>
  {({ index, style }) => (
    <div style={style}>
      <Item {...items[index]} />
    </div>
  )}
</FixedSizeList>
```

### Debounce & Throttle

```typescript
// Debounce: Wait for input to stop
import { debounce } from 'lodash-es';

const handleSearch = debounce((query: string) => {
  api.search(query);
}, 300);

// Throttle: Limit execution frequency
import { throttle } from 'lodash-es';

const handleScroll = throttle(() => {
  updateScrollPosition();
}, 100);
```

### Web Workers

```typescript
// Offload CPU-intensive work
const worker = new Worker(new URL('./worker.ts', import.meta.url));

worker.postMessage({ data: largeDataset });

worker.onmessage = (event) => {
  const result = event.data;
  updateUI(result);
};

// worker.ts
self.onmessage = (event) => {
  const result = expensiveComputation(event.data);
  self.postMessage(result);
};
```

## Memory Optimization

### Avoid Memory Leaks

```typescript
// Bad: Event listener not removed
useEffect(() => {
  window.addEventListener('resize', handleResize);
}, []); // Leak!

// Good: Cleanup
useEffect(() => {
  window.addEventListener('resize', handleResize);
  return () => window.removeEventListener('resize', handleResize);
}, []);

// Bad: Timer not cleared
useEffect(() => {
  const timer = setInterval(poll, 1000);
}, []); // Leak!

// Good: Cleanup
useEffect(() => {
  const timer = setInterval(poll, 1000);
  return () => clearInterval(timer);
}, []);
```

### WeakMap for Caches

```typescript
// Good: Garbage collected when keys are no longer referenced
const cache = new WeakMap<object, CachedData>();

function getCached(obj: object): CachedData {
  if (!cache.has(obj)) {
    cache.set(obj, computeExpensiveData(obj));
  }
  return cache.get(obj)!;
}
```

### Avoid Large Closures

```typescript
// Bad: Captures large array in closure
function createHandler(largeArray: Item[]) {
  return (id: string) => {
    // Only needs id, but captures entire array!
    return largeArray.find(item => item.id === id);
  };
}

// Good: Extract only what's needed
function createHandler(items: Map<string, Item>) {
  return (id: string) => items.get(id);
}
```

## Array & Object Operations

### Efficient Iteration

```typescript
// Fast: for loop
for (let i = 0; i < items.length; i++) {
  process(items[i]);
}

// Fast: for...of
for (const item of items) {
  process(item);
}

// Slower: forEach (function call overhead)
items.forEach(item => process(item));

// Slowest: map when not using result
items.map(item => process(item)); // Don't do this!
```

### Avoid Unnecessary Copies

```typescript
// Bad: Creates new array on every operation
let result = items;
result = result.filter(x => x.active);
result = result.map(x => x.value);
result = result.sort((a, b) => a - b);

// Good: Chain operations
const result = items
  .filter(x => x.active)
  .map(x => x.value)
  .sort((a, b) => a - b);

// Better: Single pass when possible
const result = items
  .reduce((acc, item) => {
    if (item.active) {
      acc.push(item.value);
    }
    return acc;
  }, [] as number[])
  .sort((a, b) => a - b);
```

### Object Pooling

```typescript
// Reuse objects instead of creating new ones
class ObjectPool<T> {
  private pool: T[] = [];
  
  constructor(private factory: () => T, private reset: (obj: T) => void) {}
  
  acquire(): T {
    return this.pool.pop() ?? this.factory();
  }
  
  release(obj: T): void {
    this.reset(obj);
    this.pool.push(obj);
  }
}

const vectorPool = new ObjectPool(
  () => ({ x: 0, y: 0 }),
  (v) => { v.x = 0; v.y = 0; }
);
```

## Async Optimization

### Parallel Execution

```typescript
// Bad: Sequential (slow)
const user = await fetchUser(id);
const posts = await fetchPosts(id);
const comments = await fetchComments(id);

// Good: Parallel (fast)
const [user, posts, comments] = await Promise.all([
  fetchUser(id),
  fetchPosts(id),
  fetchComments(id)
]);
```

### Request Batching

```typescript
// Bad: N requests
for (const id of userIds) {
  await fetchUser(id);
}

// Good: Single batched request
const users = await fetchUsers(userIds);
```

### Request Deduplication

```typescript
// Prevent duplicate in-flight requests
const cache = new Map<string, Promise<any>>();

async function fetchWithDedup(url: string) {
  if (cache.has(url)) {
    return cache.get(url);
  }
  
  const promise = fetch(url).then(r => r.json());
  cache.set(url, promise);
  
  try {
    return await promise;
  } finally {
    cache.delete(url);
  }
}
```

## Image Optimization

### Lazy Loading

```typescript
// Native lazy loading
<img src="image.jpg" loading="lazy" alt="..." />

// Intersection Observer for custom logic
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      const img = entry.target as HTMLImageElement;
      img.src = img.dataset.src!;
      observer.unobserve(img);
    }
  });
});

images.forEach(img => observer.observe(img));
```

### Responsive Images

```typescript
<picture>
  <source srcSet="image.webp" type="image/webp" />
  <source srcSet="image.jpg" type="image/jpeg" />
  <img src="image.jpg" alt="..." />
</picture>

// Or with srcset
<img
  src="image-800.jpg"
  srcSet="image-400.jpg 400w, image-800.jpg 800w, image-1200.jpg 1200w"
  sizes="(max-width: 600px) 400px, (max-width: 1200px) 800px, 1200px"
  alt="..."
/>
```

## Network Optimization

### HTTP/2 Server Push

```typescript
// Express with http2
import http2 from 'http2';

const server = http2.createSecureServer(options);

server.on('stream', (stream, headers) => {
  if (headers[':path'] === '/') {
    stream.pushStream({ ':path': '/style.css' }, (err, pushStream) => {
      pushStream.respondWithFile('style.css');
    });
  }
});
```

### Resource Hints

```html
<!-- Preconnect to external domains -->
<link rel="preconnect" href="https://api.example.com" />

<!-- Prefetch resources for next page -->
<link rel="prefetch" href="/next-page.js" />

<!-- Preload critical resources -->
<link rel="preload" href="/critical.css" as="style" />
```

## Caching Strategies

### Service Worker

```typescript
// sw.ts
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open('v1').then(cache => {
      return cache.addAll([
        '/',
        '/styles.css',
        '/script.js'
      ]);
    })
  );
});

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then(response => {
      return response || fetch(event.request);
    })
  );
});
```

### IndexedDB for Large Data

```typescript
// Use IndexedDB for client-side storage
import { openDB } from 'idb';

const db = await openDB('mydb', 1, {
  upgrade(db) {
    db.createObjectStore('items', { keyPath: 'id' });
  }
});

await db.add('items', { id: 1, data: '...' });
const item = await db.get('items', 1);
```

## Build Optimization

### Minification

```javascript
// Vite/Webpack automatically minifies in production
// Terser for JS, cssnano for CSS

// vite.config.ts
export default {
  build: {
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true, // Remove console.log
      }
    }
  }
};
```

### Compression

```javascript
// Enable gzip/brotli compression
import compression from 'compression';

app.use(compression());
```

## Monitoring

### Performance API

```typescript
// Measure page load
window.addEventListener('load', () => {
  const perfData = performance.getEntriesByType('navigation')[0];
  console.log('DOM loaded:', perfData.domContentLoadedEventEnd);
  console.log('Page loaded:', perfData.loadEventEnd);
});

// Custom marks
performance.mark('start-render');
render();
performance.mark('end-render');
performance.measure('render-time', 'start-render', 'end-render');
```

### Web Vitals

```typescript
import { getCLS, getFID, getFCP, getLCP, getTTFB } from 'web-vitals';

getCLS(console.log); // Cumulative Layout Shift
getFID(console.log); // First Input Delay
getFCP(console.log); // First Contentful Paint
getLCP(console.log); // Largest Contentful Paint
getTTFB(console.log); // Time to First Byte
```

## Common Pitfalls

### Avoid Synchronous Operations

```typescript
// Bad: Blocks event loop
const data = fs.readFileSync('file.txt');

// Good: Non-blocking
const data = await fs.promises.readFile('file.txt');
```

### Avoid Large Dependencies

```typescript
// Bad: 500KB library for one function
import moment from 'moment';

// Good: Use native or smaller alternative
import { format } from 'date-fns';
// Or use native Intl.DateTimeFormat
```

### Avoid Premature Optimization

```typescript
// Don't optimize until you measure!
// Profile first, then optimize bottlenecks
```
