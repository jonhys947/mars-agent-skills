---
name: react-patterns
description: Modern React patterns, hooks, composition, and performance optimization. Use for React component development.
---

# React Patterns Skill

## Core Principles

- **Composition Over Inheritance**: Build with small, reusable components
- **Unidirectional Data Flow**: Props down, events up
- **Declarative UI**: Describe what, not how
- **Immutable State**: Never mutate state directly
- **Single Responsibility**: One component, one purpose

## Component Patterns

### Functional Components (Default)

```typescript
// Good: Typed props interface
interface ButtonProps {
  label: string;
  onClick: () => void;
  variant?: 'primary' | 'secondary';
  disabled?: boolean;
}

export function Button({ label, onClick, variant = 'primary', disabled = false }: ButtonProps) {
  return (
    <button
      className={`btn btn-${variant}`}
      onClick={onClick}
      disabled={disabled}
    >
      {label}
    </button>
  );
}
```

### Composition Patterns

```typescript
// Good: Children prop for composition
interface CardProps {
  children: React.ReactNode;
  title?: string;
}

export function Card({ children, title }: CardProps) {
  return (
    <div className="card">
      {title && <h3>{title}</h3>}
      {children}
    </div>
  );
}

// Good: Compound components
export function Tabs({ children }: { children: React.ReactNode }) {
  return <div className="tabs">{children}</div>;
}

Tabs.Panel = function TabPanel({ children }: { children: React.ReactNode }) {
  return <div className="tab-panel">{children}</div>;
};

// Usage
<Tabs>
  <Tabs.Panel>Content 1</Tabs.Panel>
  <Tabs.Panel>Content 2</Tabs.Panel>
</Tabs>
```

## Hooks Best Practices

### useState

```typescript
// Good: Functional updates for derived state
const [count, setCount] = useState(0);
setCount(prev => prev + 1);

// Good: Lazy initialization for expensive computation
const [data, setData] = useState(() => expensiveComputation());

// Good: Multiple state variables for unrelated state
const [name, setName] = useState('');
const [email, setEmail] = useState('');

// Bad: Single object for unrelated state (causes unnecessary re-renders)
const [form, setForm] = useState({ name: '', email: '' });
```

### useEffect

```typescript
// Good: Cleanup function
useEffect(() => {
  const subscription = api.subscribe(data => setData(data));
  return () => subscription.unsubscribe();
}, []);

// Good: Dependency array with all dependencies
useEffect(() => {
  fetchUser(userId).then(setUser);
}, [userId]);

// Good: Separate effects for separate concerns
useEffect(() => {
  // Effect 1: Fetch user
  fetchUser(userId).then(setUser);
}, [userId]);

useEffect(() => {
  // Effect 2: Track analytics
  analytics.track('page_view', { userId });
}, [userId]);
```

### Custom Hooks

```typescript
// Good: Extract reusable logic
function useLocalStorage<T>(key: string, initialValue: T) {
  const [value, setValue] = useState<T>(() => {
    const stored = localStorage.getItem(key);
    return stored ? JSON.parse(stored) : initialValue;
  });

  useEffect(() => {
    localStorage.setItem(key, JSON.stringify(value));
  }, [key, value]);

  return [value, setValue] as const;
}

// Good: Async data fetching hook
function useAsync<T>(asyncFn: () => Promise<T>, deps: React.DependencyList) {
  const [state, setState] = useState<{
    loading: boolean;
    data?: T;
    error?: Error;
  }>({ loading: true });

  useEffect(() => {
    let cancelled = false;
    setState({ loading: true });

    asyncFn()
      .then(data => !cancelled && setState({ loading: false, data }))
      .catch(error => !cancelled && setState({ loading: false, error }));

    return () => { cancelled = true; };
  }, deps);

  return state;
}
```

### useMemo and useCallback

```typescript
// Good: Memoize expensive computations
const sortedItems = useMemo(() => {
  return items.sort((a, b) => a.name.localeCompare(b.name));
}, [items]);

// Good: Memoize callbacks passed to child components
const handleClick = useCallback(() => {
  doSomething(id);
}, [id]);

// Bad: Premature optimization
const value = useMemo(() => x + y, [x, y]); // Unnecessary for simple operations
```

### useRef

```typescript
// Good: DOM references
const inputRef = useRef<HTMLInputElement>(null);

useEffect(() => {
  inputRef.current?.focus();
}, []);

// Good: Mutable values that don't trigger re-renders
const countRef = useRef(0);

function handleClick() {
  countRef.current += 1;
  console.log('Clicked', countRef.current, 'times');
}
```

## State Management Patterns

### Lifting State Up

```typescript
// Good: Shared state in common ancestor
function Parent() {
  const [selected, setSelected] = useState<string | null>(null);

  return (
    <>
      <ChildA selected={selected} onSelect={setSelected} />
      <ChildB selected={selected} />
    </>
  );
}
```

### Context for Deep Props

```typescript
// Good: Context for theme, auth, etc.
interface ThemeContextValue {
  theme: 'light' | 'dark';
  toggleTheme: () => void;
}

const ThemeContext = createContext<ThemeContextValue | undefined>(undefined);

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setTheme] = useState<'light' | 'dark'>('light');
  
  const toggleTheme = useCallback(() => {
    setTheme(prev => prev === 'light' ? 'dark' : 'light');
  }, []);

  return (
    <ThemeContext.Provider value={{ theme, toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within ThemeProvider');
  }
  return context;
}
```

### Reducer for Complex State

```typescript
// Good: useReducer for complex state logic
type State = {
  items: Item[];
  filter: string;
  sort: 'asc' | 'desc';
};

type Action =
  | { type: 'ADD_ITEM'; item: Item }
  | { type: 'REMOVE_ITEM'; id: string }
  | { type: 'SET_FILTER'; filter: string }
  | { type: 'TOGGLE_SORT' };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'ADD_ITEM':
      return { ...state, items: [...state.items, action.item] };
    case 'REMOVE_ITEM':
      return { ...state, items: state.items.filter(i => i.id !== action.id) };
    case 'SET_FILTER':
      return { ...state, filter: action.filter };
    case 'TOGGLE_SORT':
      return { ...state, sort: state.sort === 'asc' ? 'desc' : 'asc' };
  }
}

function Component() {
  const [state, dispatch] = useReducer(reducer, initialState);
  // ...
}
```

## Performance Optimization

### React.memo

```typescript
// Good: Memoize expensive components
export const ExpensiveComponent = React.memo(function ExpensiveComponent({ 
  data 
}: { 
  data: Data 
}) {
  // Expensive rendering logic
  return <div>{/* ... */}</div>;
});

// Good: Custom comparison
export const UserCard = React.memo(
  function UserCard({ user }: { user: User }) {
    return <div>{user.name}</div>;
  },
  (prev, next) => prev.user.id === next.user.id
);
```

### Code Splitting

```typescript
// Good: Lazy load routes
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

### Virtualization

```typescript
// Good: Virtualize long lists
import { FixedSizeList } from 'react-window';

function VirtualList({ items }: { items: Item[] }) {
  return (
    <FixedSizeList
      height={600}
      itemCount={items.length}
      itemSize={50}
      width="100%"
    >
      {({ index, style }) => (
        <div style={style}>{items[index].name}</div>
      )}
    </FixedSizeList>
  );
}
```

## Error Boundaries

```typescript
// Good: Error boundary for graceful failures
class ErrorBoundary extends React.Component<
  { children: React.ReactNode; fallback: React.ReactNode },
  { hasError: boolean }
> {
  state = { hasError: false };

  static getDerivedStateFromError() {
    return { hasError: true };
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    console.error('Error caught:', error, info);
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback;
    }
    return this.props.children;
  }
}
```

## Form Handling

```typescript
// Good: Controlled components
function LoginForm() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    login({ email, password });
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="email"
        value={email}
        onChange={e => setEmail(e.target.value)}
      />
      <input
        type="password"
        value={password}
        onChange={e => setPassword(e.target.value)}
      />
      <button type="submit">Login</button>
    </form>
  );
}
```

## Testing Patterns

```typescript
// Good: Test user behavior, not implementation
import { render, screen, fireEvent } from '@testing-library/react';

test('increments counter on button click', () => {
  render(<Counter />);
  
  const button = screen.getByRole('button', { name: /increment/i });
  const count = screen.getByText(/count: 0/i);
  
  fireEvent.click(button);
  
  expect(screen.getByText(/count: 1/i)).toBeInTheDocument();
});
```

## Common Pitfalls

### Avoid Inline Object/Array Creation in Props

```typescript
// Bad: Creates new object every render
<Component style={{ margin: 10 }} />

// Good: Define outside or use useMemo
const style = { margin: 10 };
<Component style={style} />
```

### Avoid Conditional Hooks

```typescript
// Bad: Hooks must be called unconditionally
if (condition) {
  useEffect(() => { /* ... */ }, []);
}

// Good: Condition inside hook
useEffect(() => {
  if (condition) {
    // ...
  }
}, [condition]);
```

### Key Prop for Lists

```typescript
// Bad: Index as key (causes issues with reordering)
{items.map((item, index) => <Item key={index} {...item} />)}

// Good: Stable unique identifier
{items.map(item => <Item key={item.id} {...item} />)}
```
