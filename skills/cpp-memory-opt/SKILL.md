---
name: cpp-memory-opt
description: "ESP32 heap/stack/buffer optimization for pool-controller firmware. Use when asked to reduce memory usage, fix heap fragmentation, eliminate String in loops, resize JSON buffers, or optimize RAM in the pool-controller C++ codebase. 🇩🇪 Deutsche Trigger: Speicheroptimierung, Heap-Fragmentierung beheben, String-Eliminierung, JSON-Puffer anpassen, RAM-Optimierung, Stack-Größe, statische Puffer."
metadata:
  keywords:
    - speicheroptimierung
    - memory optimization
    - heap fragmentierung
    - heap fragmentation
    - string elimination
    - json puffer
    - json buffer
    - ram optimierung
    - stack größe
    - statische puffer
    - static buffer
    - arduinojson
    - preferences nvs
---

# ESP32 Memory Optimization — Pool Controller

This skill's file names, thresholds, and APIs refer only to the ESP32 pool-controller project using PlatformIO, Arduino, and C++17. Verify them in that project's current checkout before relying on them. For another target, use only the general measurement ideas and derive limits, buffer sizes, and allocation choices from that project's contracts, toolchain, and runtime data.

> The original pool-controller workflow used `semble search "String concat in loop"`
> and `semble search "StaticJsonDocument"`. Use those commands only if `semble`
> is installed and configured for the target checkout; otherwise use the project's
> available code-search tools. Its `Agents.md` reference is project-local.

## Key Constraints

- **Platform**: ESP32 (esp32dev), ~320KB SRAM, ~4MB flash
- **Framework**: Arduino + ESP-IDF (FreeRTOS)
- **Critical**: 24/7 operation with no memory leaks
- **Heap threshold**: Warning at <16KB free, reboot at <8KB free (`SystemMonitor.hpp:26-27`)
- **Watchdog**: TWDT with 30s timeout (`SystemMonitor.hpp:49-54`)

## Common Memory Issues & Fixes in This Project

### 1. Eliminate `String` Objects in Loop/Hot-Paths

**BAD** (in `MqttPublisher.cpp`, `OperationModeNode.cpp`):

```cpp
// AVOID: frequent allocations fragment heap
String result = "";
for (int i = 0; i < count; i++) {
    result += someValue;  // realloc each iteration!
}
```

**GOOD** — use `snprintf` or pre-reserved buffers:

```cpp
// PREFER: stack-allocated or pre-reserved buffer
char buffer[128];
snprintf(buffer, sizeof(buffer), "format %s %d", str, val);
```

**Pattern in this project**: `Utils.hpp` provides `floatToString()` and `intToString()` wrappers.

- Use `Utils::floatToString(value, buf, sizeof(buf))` instead of `String(value)` in temperature paths
- Use `Utils::intToString(value, buf, sizeof(buf))` instead of `String(value)` in interval paths

### 2. `StaticJsonDocument` Sizing

**Location**: `MqttPublisher.cpp`, `WebPortal.cpp`, `ConfigManager.cpp`

Sizing guidance adapted for the pool-controller's JSON sites (confirm its current `Agents.md` policy and ArduinoJson version before applying):

- Size `StaticJsonDocument` using the [ArduinoJson Assistant](https://arduinojson.org/v6/assistant/)
- Derive capacity from the maximum serialized output and the exact ArduinoJson version/API. Reserve the space the serializer requires and check its result or truncation status; there is no universal percentage margin.
- Ensure the destination's actual capacity can hold the maximum output, including any required terminator; handle insufficient capacity explicitly.
- Choose local, static, pooled, or heap storage from the measured stack/heap budgets, object lifetime, reuse, and concurrent call count. A byte threshold alone does not determine safe placement.

**CHECK**: For each JSON serialization in the codebase, verify:

```
requiredSize = serializer_size_for_this_version(doc)
writtenSize  = serialize_using_the_project_api(doc, destination, capacity)
verify writtenSize and the API's truncation/error result
```

### 3. Stack vs Heap Allocation

- **Function-local** = stack (freed on return) — prefer for temporary use
- **File-scope `static`** = BSS/data segment (never freed) — use only for persistent state
- **Heap (`new`/`malloc`)** = managed pool — fragment-prone

### Storage selection

Choose storage from actual peak stack capacity, memory region, lifetime, reuse, and concurrency. A fixed size such as 512 bytes is not a general stack-versus-static rule. For this project, check its current `Agents.md` guidance before changing established placement.

### 4. Pin Configuration Validation

Already implemented in `PoolController.cpp:56-84` — uses `uint8_t` array, not `std::vector`.

### 5. NVS Preferences Usage

`StateManager.hpp` uses ESP32 Preferences. Best practices:

- Open `Preferences` with `readOnly=true` when only reading (`prefs.begin("ns", true)`)
- Close with `prefs.end()` promptly
- Batch writes — don't write each property individually in loops

### 6. Known High-Allocation Areas to Audit

| File                    | Risk                                | Action                                                            |
| ----------------------- | ----------------------------------- | ----------------------------------------------------------------- |
| `MqttPublisher.cpp`     | JSON serialization per HA discovery | Verify `StaticJsonDocument` size + buffer margin                  |
| `OperationModeNode.cpp` | State persistence on every setter   | Already has `_suppressPersist` guard — verify it's used correctly |
| `WebPortal.cpp`         | HTTP response construction          | Check for `String` concatenation                                  |
| `NetworkManager.cpp`    | WiFi/MQTT reconnection              | Verify no String allocations in retry paths                       |

## Diagnosis Commands

```bash
# PlatformIO check with memory analysis
pio check --environment esp32dev --skip-packages

# Build with memory map
pio run -e esp32dev --verbose 2>&1 | grep -E "(\.text|\.data|\.bss|\.rodata|DRAM|IRAM)"

# Flash size analysis
pio run -e esp32dev --target size
pio run -e esp32dev --target size-components

# Check free heap at runtime (monitor output)
# Look for: "Free heap: X B" in serial output
```

## Heap Fragmentation Test Pattern

```cpp
// Add this temporarily to PoolController::loop() to track fragmentation:
static uint32_t lastFragCheck = 0;
if (millis() - lastFragCheck > 60000) {  // Every 60s
    lastFragCheck = millis();
    Serial.printf("HEAP: free=%u largest=%u frag=%u%%\n",
        ESP.getFreeHeap(),
        heap_caps_get_largest_free_block(MALLOC_CAP_DEFAULT),
        100 - (heap_caps_get_largest_free_block(MALLOC_CAP_DEFAULT) * 100 / ESP.getFreeHeap()));
}
```

---

## 📚 References & Best Practices

### ESP32 Memory Management

- **[ESP32 Memory Types](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/memory-types.html)**

  Official Espressif memory architecture documentation

- **[ESP32 Memory Allocation](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/memory-management.html)**

  Memory allocation strategies and best practices

- **[ESP32 Heap Fragmentation](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/heap-fragmentation.html)**

  Understanding and preventing heap fragmentation

- **[ESP-IDF Memory Debugging](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/debugging/memory-leaks.html)**

  Tools and techniques for memory leak detection

### Arduino & C++ Memory Optimization

- **[Arduino String vs char arrays](https://www.arduino.cc/en/Reference/String)**

  When to use String vs char arrays

- **[ArduinoJson Memory Optimization](https://arduinojson.org/v6/how-to/reduce-memory-usage/)**

  Reducing memory usage with ArduinoJson

- **[ArduinoJson Assistant](https://arduinojson.org/v6/assistant/)**

  Calculate required buffer sizes

- **[Google C++ Style Guide - Memory Management](https://google.github.io/styleguide/cppguide.html#Ownership_and_Smart_Pointers)**

  Smart pointer usage guidelines

### Memory Analysis Tools

- **[PlatformIO Memory Analysis](https://docs.platformio.org/en/latest/plus/debug-tools/memcheck.html)**

  Memory usage analysis with PlatformIO

- **[Valgrind for Embedded](https://valgrind.org/)**

  Memory leak detection (for native builds)

- **[Heap Usage Monitoring](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/system/heap_debug.html)**

  ESP32 heap debugging functions

### Practical Implementation Guides

- **[ESP32 Memory Optimization Guide](https://github.com/espressif/esp-idf/blob/master/docs/en/api-guides/memory-types.rst)**

  Official memory optimization strategies

- **[Avoiding String in Arduino](https://hackingmajenkoblog.wordpress.com/2016/02/04/the-evils-of-arduino-strings/)**

  Why and how to avoid String class

- **[Static vs Dynamic Allocation](https://embeddedartistry.com/blog/2017/02/22/always-use-the-right-sized-integer/)**

  Choosing the right allocation strategy

---

**🔍 Analysis Note**: This skill was enhanced during the comprehensive IoT security
and memory analysis performed by Vibe Code on 2025-01-15. See
[PR #112](https://github.com/smart-swimmingpool/pool-controller/pull/112)
for implementation details and memory optimization examples.
