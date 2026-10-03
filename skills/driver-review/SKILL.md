---
name: driver-review
description: Review or implement embedded hardware drivers for DMA, interrupts, timing, peripheral registers, and test doubles. Use when changing or reviewing MCU drivers; apply FastLED channel-engine examples only in repositories that use FastLED.
disable-model-invocation: true
---

# Hardware Driver Review & Implementation Guide

Use the general safety checks with the active project's hardware contract, APIs, and toolchain. The implementation examples and named `fl` types below come from FastLED; apply them only when the target repository uses FastLED, and never introduce them into another project by default.

## Your Task

1. For review or implementation in a Git repository, inspect the relevant staged and unstaged diff without discarding user changes
2. Identify files that are hardware driver code (see "What Counts as Driver Code" below)
3. For **reviews**: Check relevant driver changes against the rules below and report findings; change reviewed code only when the user asks for fixes
4. For **implementations**: Follow the requested scope and use applicable FastLED patterns below
5. Report the summary and evidence

## What Counts as Driver Code

Files matching these patterns:
- `src/platforms/**` — Platform-specific implementations
- `src/fl/channels/**` — LED channel engine and DMA pipeline
- `**/drivers/**` — Hardware driver implementations
- Files containing: DMA buffers, SPI/I2S/RMT/UART/PARLIO peripheral access, GPIO configuration, interrupt handlers, timer configuration

---

# Part 1: Review Rules

### 1. DMA Safety
- [ ] Check the selected chip, peripheral, driver API, and build configuration for required memory region, alignment, cache maintenance, and transfer-size limits. Do not assume ESP-IDF heap capabilities or a fixed alignment across FastLED targets.
- [ ] Keep the buffer and descriptors valid for the full transfer; use static or allocated storage when an asynchronous transfer outlives the call that starts it.
- [ ] Verify ownership and cleanup on success, error, cancellation, and timeout paths.

### 2. Interrupt Safety
- [ ] Use the platform's ISR placement attributes only as required by the target and interrupt configuration. On ESP32, cache-off handlers need the complete reachable code and data in accessible memory; `IRAM_ATTR` alone does not guarantee that.
- [ ] Avoid allocation in ISRs unless the target's documented ISR-safe allocator explicitly permits it; prefer preallocated state
- [ ] Do not block in an ISR. Use the platform's ISR-safe signaling APIs; never pass a blocking timeout from interrupt context. `portMAX_DELAY` is not a zero-timeout value.
- [ ] Avoid logging or formatted I/O in ISRs unless the platform documents a safe, bounded ISR logging path
- [ ] Check whether this interrupt can run while flash cache is unavailable; keep all reachable code/data accessible then if required by the target.
- [ ] If the project uses FreeRTOS, use the matching `FromISR` APIs and respect the configured interrupt-priority ceiling.
- [ ] Use the platform's documented interrupt-context critical-section primitive when one is needed; do not substitute a task-context lock or API without confirming it is ISR-safe
- [ ] Follow the selected platform's ISR return and yield conventions.

### 3. Peripheral Register Access
- [ ] Registers accessed through volatile pointers or HAL functions
- [ ] No read-modify-write races on shared registers (use atomic or critical section)
- [ ] Peripheral clock enabled before register access
- [ ] Peripheral properly initialized before use and cleaned up on teardown
- [ ] GPIO matrix/IOMUX configured correctly for peripheral signals

### 4. Timing Constraints
- [ ] For LED protocols in scope, compare clock and reset timing against the current protocol specification and the selected peripheral's timing limits; do not reuse one chipset's values for another.
- [ ] No blocking waits in time-critical paths
- [ ] Long-running work obeys the configured watchdog and scheduling policy; use the project's supported yield or timeout mechanism where appropriate.

### 5. Memory Safety
- [ ] Buffer sizes checked before DMA transfer setup
- [ ] No buffer overflows in encoding functions (bounds checking on output buffer)
- [ ] Calculate encoded output size from the selected representation (the `wave8` example applies only where that FastLED encoder is used)
- [ ] Align chunk sizes to the selected peripheral/API requirements; do not assume a universal SPI alignment

### 6. FastLED Channel Engine Patterns (conditional)

Apply this section only to a FastLED channel-engine change; state names and APIs are FastLED-specific.
- [ ] `show()` waits for `poll() == READY` before starting new frame
- [ ] No branching on intermediate states (DRAINING, STREAMING) in wait loops
- [ ] Channel released after transmission complete (frees peripheral for next channel)
- [ ] State machine handles all transitions (no stuck states)
- [ ] Error recovery path exists (timeout, reset to IDLE)

### 7. FastLED Peripheral Mock Example (conditional)

Apply these conventions only to FastLED mocks whose existing test contract uses this synchronous simulation model. For another driver or an asynchronous interface, model the documented completion, cancellation, timing, and concurrency behavior of that API instead; do not require these names or a singleton mock.

- [ ] **NO background threads** — mock must be fully synchronous
- [ ] Avoid wall-clock sleeps in deterministic unit tests; use the test framework's virtual time or controlled completion mechanism when available
- [ ] Avoid synchronization primitives when the mock and test are intentionally single-threaded; preserve them when concurrent behavior is part of the contract
- [ ] Synchronous callback pump via `pumpDeferredCallbacks()` with re-entrancy guard
- [ ] `waitDone()` returns instantly — never polls or sleeps
- [ ] `reset()` clears ALL state — called between test cases for isolation
- [ ] Transmitted data captured in history vector for test inspection
- [ ] Singleton via `fl::Singleton<Impl>`

### 8. Power and Reset
- [ ] Check brown-out handling only where the selected chip and product requirements need it
- [ ] Reset peripherals and drive pins to safe states only when required by their datasheets, board bindings, and the existing lifecycle contract
- [ ] Respect documented power-domain and light-sleep constraints; do not add reset, GPIO, or sleep behavior without an authorized hardware binding

### 9. Multi-Platform Considerations
- [ ] Platform guards use the project's actual compiler and target macros; examples such as `ESP32` or `FL_IS_ARM` are not portable names
- [ ] No platform-specific types leaking into shared headers
- [ ] Fallback/no-op implementations for unsupported platforms
- [ ] Integer types match the project's conventions and the target ABI

---

# Part 2: Implementation Guide

## Architecture

FastLED's driver stack has three layers:

```
IChannelDriver              (driver.h — show/poll state machine)
  └─ ChannelEngine*         (groups channels by timing, iterates chipset groups)
      └─ IPeripheral        (virtual interface — real HW or mock)
          ├─ PeripheralEsp  (real ESP-IDF calls)
          └─ PeripheralMock (synchronous test simulation)
```

## File Structure for New Peripheral `foo`

```
src/platforms/esp/32/drivers/foo/
  ├─ ifoo_peripheral.h              # Virtual interface (no ESP-IDF types)
  ├─ foo_peripheral_esp.h           # Real hardware implementation
  ├─ foo_peripheral_mock.h          # Mock class declaration
  ├─ foo_peripheral_mock.cpp.hpp    # Mock implementation (synchronous)
  └─ channel_driver_foo.cpp.hpp     # Channel driver using IFooPeripheral

tests/platforms/esp/32/drivers/foo/
  ├─ foo_peripheral_mock.cpp        # Mock peripheral unit tests
  └─ channel_driver_foo.cpp         # Driver integration tests
```

**Reference implementations:**
- I2S: `src/platforms/esp/32/drivers/i2s/`
- LCD_CAM: `src/platforms/esp/32/drivers/lcd_cam/`
- PARLIO: `src/platforms/esp/32/drivers/parlio/`

## FastLED Peripheral Interface Example (conditional)

Define the virtual interface in `ifoo_peripheral.h`:

- **No ESP-IDF types** — use `void*`, `u16*`, basic types only
- All methods `FL_NOEXCEPT override`
- Buffer management follows the selected peripheral's documented memory-region and alignment requirements; do not hardcode 64-byte alignment
- Time simulation: `getMicroseconds()`, `delay(ms)`
- Callback registration: `registerCallback(void* fn, void* ctx)`

## Peripheral Mock Implementation

### Required Members

```cpp
// Lifecycle
bool mInitialized, mEnabled, mBusy;
size_t mTransmitCount;
FooConfig mConfig;

// ISR callback
void* mCallback;
void* mUserCtx;

// Simulation settings
u32 mTransmitDelayUs;
bool mTransmitDelayForced;
bool mShouldFailTransmit;

// Test inspection
fl::vector<TransmitRecord> mHistory;

// Pending state
size_t mPendingTransmits;

// Simulated time (deterministic — advances only via delay() calls)
u64 mSimulatedTimeUs;

// Synchronous callback pump
bool mFiringCallbacks;            // Re-entrancy guard
size_t mDeferredCallbackCount;    // Pending callbacks to fire
```

### Core Pattern: transmit() → pump → fireCallback()

**transmit()** — Queue + pump:
```cpp
bool transmit(const u16* buffer, size_t size_bytes) {
    if (!mInitialized || mShouldFailTransmit) return false;

    // Capture data for test inspection
    TransmitRecord record;
    record.buffer_copy.resize(size_bytes / 2);
    fl::memcpy(record.buffer_copy.data(), buffer, size_bytes);
    record.size_bytes = size_bytes;
    record.timestamp_us = mSimulatedTimeUs;
    mHistory.push_back(fl::move(record));

    // Queue + fire synchronously
    mTransmitCount++;
    mBusy = true;
    mPendingTransmits++;
    mDeferredCallbackCount++;
    pumpDeferredCallbacks();
    return true;
}
```

**waitDone()** — Instant check, never polls:
```cpp
bool waitDone(u32 timeout_ms) {
    if (!mInitialized) return false;
    (void)timeout_ms;  // Not used — synchronous mock
    if (mPendingTransmits == 0) { mBusy = false; return true; }
    return false;
}
```

**pumpDeferredCallbacks()** — Re-entrant safe:
```cpp
void pumpDeferredCallbacks() {
    if (mFiringCallbacks) return;  // Re-entrancy guard
    mFiringCallbacks = true;
    while (mDeferredCallbackCount > 0) {
        mDeferredCallbackCount--;
        fireCallback();
    }
    mFiringCallbacks = false;
}
```

**fireCallback()** — One callback at a time:
```cpp
void fireCallback() {
    if (mPendingTransmits > 0) mPendingTransmits--;
    if (mPendingTransmits == 0) mBusy = false;
    if (mCallback != nullptr) {
        using CallbackType = bool (*)(void*, const void*, void*);
        auto fn = reinterpret_cast<CallbackType>(mCallback);
        fn(nullptr, nullptr, mUserCtx);
    }
}
```

**Time simulation:**
```cpp
u64 getMicroseconds() { return mSimulatedTimeUs; }
void delay(u32 ms) { mSimulatedTimeUs += static_cast<u64>(ms) * 1000; }
```

**reset()** — Full state reset:
```cpp
void reset() {
    mInitialized = mEnabled = mBusy = false;
    mTransmitCount = 0;
    mConfig = FooConfig();
    mCallback = nullptr; mUserCtx = nullptr;
    mTransmitDelayUs = 0; mTransmitDelayForced = false; mShouldFailTransmit = false;
    mHistory.clear(); mPendingTransmits = 0;
    mSimulatedTimeUs = 0; mFiringCallbacks = false; mDeferredCallbackCount = 0;
}
```

### Mock-Specific Test API (required)

```cpp
void simulateTransmitComplete();           // Manually complete one pending transmit
void setTransmitFailure(bool should_fail); // Force transmit() to return false
void setTransmitDelay(u32 microseconds);   // Set forced delay
const fl::vector<TransmitRecord>& getTransmitHistory() const;
fl::span<const u16> getLastTransmitData() const;
size_t getTransmitCount() const;
bool isEnabled() const;
void clearTransmitHistory();
void reset();
```

## Channel Driver

Implement `IChannelDriver`. State machine:
```
READY → (enqueue) → READY → (show) → BUSY → (poll) → DRAINING → (poll) → READY
```

**Constructor pattern:**
```cpp
ChannelDriverFoo();                                          // Production
ChannelDriverFoo(fl::shared_ptr<IFooPeripheral> peripheral); // Testing
```

**Chipset grouping:** Channels with different timing (T0H, T1H, T0L, T1L) must be transmitted in separate groups. Sort by transmission time.

## Tests

```cpp
namespace {
void resetFooMockState() {
    auto& mock = FooPeripheralMock::instance();
    mock.reset();  // CRITICAL: reset between every test
}
}

FL_TEST_CASE("FooPeripheralMock - basic transmit") {
    resetFooMockState();
    auto& mock = FooPeripheralMock::instance();
    FooConfig config;
    config.num_lanes = 4;
    config.pclk_hz = 3200000;
    FL_REQUIRE(mock.initialize(config));
    u16* buffer = mock.allocateBuffer(1024);
    FL_REQUIRE(buffer != nullptr);
    FL_CHECK(mock.transmit(buffer, 1024));
    FL_CHECK(mock.waitDone(100));
    FL_CHECK(mock.getTransmitCount() == 1);
    mock.freeBuffer(buffer);
}
```

## FastLED Driver Registration Priority (conditional)

In `channel_manager_esp32.cpp.hpp`:
- PARLIO: 4 (highest)
- LCD_RGB: 3
- RMT: 2
- I2S: 1
- SPI: 0
- UART: -1

## Buffer Alignment and Allocation

Determine alignment, addressability, cache-coherency, transfer-length, and lifetime constraints from the active FastLED platform driver and target documentation. Use the allocator or declaration pattern supported by that target. The FastLED examples above use `fl` types because they belong to that codebase; they are not APIs to introduce into other projects.

---

## Output Format (for reviews)

```
## Hardware Driver Review Results

### File-by-file Analysis
- **src/platforms/esp/32/drivers/spi/channel_engine_spi.cpp.hpp**: [findings]

### Findings by Category
- **DMA Safety**: N issues
- **Interrupt Safety**: N issues
- **Mock Rules**: N issues
- **Timing Constraints**: N issues

### Summary
- Files reviewed: N
- Violations found: N
- Violations fixed: N
```

## Instructions
- Focus on driver/platform code — skip application-level changes
- Be thorough on DMA and interrupt safety (these cause hard-to-debug crashes)
- Assess mock findings by the reproduced behavior and consequence: for example, whether the test is nondeterministic, hides an async completion race, or disagrees with the driver contract. Assign a priority only with evidence and the project's severity scheme.
- Follow the project's C++ standard and style guidance when present; a FastLED reference such as `agents/docs/cpp-standards.md` may not exist in another repository
- For implementation requests, make in-scope changes directly and describe material tradeoffs; do not seek routine confirmation for significant work the user already requested
- Ask only when a genuine contract or scope ambiguity blocks safe progress, or an additional gated action lacks authorization
