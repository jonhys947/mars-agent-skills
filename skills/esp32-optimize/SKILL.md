---
name: esp32-optimize
description: ESP-IDF performance optimization for ESP32 firmware. Use this skill whenever working on ESP32/ESP-IDF code and the user asks about RAM usage, memory optimization, binary size reduction, speed optimization, IRAM pressure, stack sizing, heap fragmentation, sdkconfig tuning, startup time, or any performance concern on embedded targets. Also trigger when the user mentions slow firmware, out-of-memory crashes, IRAM overflow linker errors, or large binary sizes.
---

# ESP-IDF Performance Optimization

This guidance is for ESP-IDF projects. SoC family, ESP-IDF version, sdkconfig,
board memory, and application architecture affect which APIs and Kconfig options
exist and what they cost. Verify those in the active repository before applying
an example; values below are not cross-target defaults.

You are an ESP-IDF performance expert. When optimizing ESP32 firmware, follow this methodology:

1. **Identify** the bottleneck (speed, RAM, binary size, startup time, or IRAM overflow)
2. **Measure** current state before changing anything
3. **Apply** targeted optimizations from the relevant section below
4. **Re-measure** and verify no regressions

Check the validation relevant to the requested change: target build, runtime
behavior, and measured resource headroom. Do not claim hardware validation
without the corresponding hardware run.

---

## Measuring

### Static sizes

# These wrapper commands are specific to the mikrojs workspace; use the target
# repository's documented build wrapper or ESP-IDF version otherwise.
```bash
pn mikro idf size              # overview: .text, .data, .bss, .rodata
pn mikro idf size-components   # per-component breakdown
pn mikro idf size-files        # per-file breakdown
```

### Dynamic / runtime

```c
// Heap
esp_get_free_heap_size()
esp_get_minimum_free_heap_size()  // all-time low
// Also check largest free block for fragmentation

// Stack high water mark (call after peak usage)
uxTaskGetStackHighWaterMark(NULL)  // current task, returns bytes on ESP32
uxTaskGetSystemState()             // all tasks summary

// Timing
#include "esp_timer.h"
uint64_t t0 = esp_timer_get_time();  // microseconds
// ... work ...
uint64_t elapsed_us = esp_timer_get_time() - t0;

// Cycle-accurate (from pinned task only)
#include "esp_cpu.h"
uint32_t cycles = esp_cpu_get_cycle_count();  // cpu_hal_get_cycle_count() is removed in IDF 6

// Per-task CPU time
// Enable CONFIG_FREERTOS_GENERATE_RUN_TIME_STATS, then call vTaskGetRunTimeStats()
```

---

## RAM Optimization

### Reducing static RAM (DRAM)

- Constant data may be placed in flash when qualifiers, linker script, and target configuration allow it; confirm the map file.
- Bluetooth allocation options depend on the selected stack and IDF/SoC version. Check the active Kconfig documentation and lifecycle before changing them.

### Reducing IRAM (SoC and memory-map dependent)

| Config                                         | Effect                  | Safe?                                               |
| ---------------------------------------------- | ----------------------- | --------------------------------------------------- |
| `CONFIG_FREERTOS_PLACE_FUNCTIONS_INTO_FLASH=y` | May place FreeRTOS functions in flash | Only after checking interrupt/cache-off call paths for this SDK |
| `CONFIG_RINGBUF_PLACE_FUNCTIONS_INTO_FLASH=y`  | May place ring-buffer functions in flash | Only after checking ISR and cache-off call paths |
| `CONFIG_HEAP_PLACE_FUNCTION_INTO_FLASH=y`      | May place heap functions in flash | Check allocator use from interrupts and cache-off paths |
| `CONFIG_LIBC_LOCKS_PLACE_IN_IRAM=n`            | May move libc locks out of IRAM | Check all callers and cache-disabled behavior |
| Disable `CONFIG_ESP_WIFI_IRAM_OPT`             | Frees WiFi IRAM         | Costs WiFi throughput                               |
| Disable `CONFIG_ESP_WIFI_RX_IRAM_OPT`          | Frees WiFi RX IRAM      | Costs WiFi RX throughput                            |
| `CONFIG_ESP32_REV_MIN_3=y` (ECO3 only)         | Drops PSRAM workarounds | Saves 10+ KB IRAM                                   |
| Disable `CONFIG_ESP_EVENT_POST_FROM_IRAM_ISR`  | esp_event IRAM          | Can't post events from IRAM ISR                     |
| Disable `CONFIG_SPI_MASTER_ISR_IN_IRAM`        | SPI master ISR          | ISR paused during flash writes                      |
| `CONFIG_HAL_DEFAULT_ASSERTION_LEVEL=0`         | Changes HAL assertion behavior/reporting | Only after reviewing the exact option and retaining required invariant checks |

These option names and effects vary across ESP-IDF releases and targets. Confirm
each option exists in the active SDK and check its dependencies, ISR call paths,
and runtime tradeoffs before editing `sdkconfig`.

An IRAM overflow linker error can look like `section '.iram0.text' will not fit in region 'iram0_0_seg'`. Use the active SDK's map/size tools to find consumers; `pn mikro idf size-components` is only the mikrojs workspace wrapper.

IRAM and DRAM partitioning depends on the SoC and build configuration; reducing
one region may not free usable capacity in the other. Inspect the target's
linker map and SDK memory documentation.

### Stack optimization

- Profile and analyze peak call paths with the target's stack tools. Account for worst-case inputs, nested calls, interrupts, and the project's justified safety margin; do not use a fixed percentage without a requirement.
- `printf`/`snprintf` are heavy stack users. In ESP-IDF 6.x Picolibc is the default libc (`CONFIG_LIBC_PICOLIBC=y`); `CONFIG_NEWLIB_NANO_FORMAT` no longer exists (it was IDF 5.x, only relevant with `CONFIG_LIBC_NEWLIB=y`)
- Evaluate local objects against the specific task's stack budget and object lifetime. Static or heap storage also has costs, ownership, and concurrency implications; choose from measured constraints rather than a size cutoff.
- Minimize recursion
- Consolidate tasks where possible — no task = no stack allocation

Key task stack config options (profile before reducing):

| Config                                    | Default | Notes                             |
| ----------------------------------------- | ------- | --------------------------------- |
| `CONFIG_ESP_MAIN_TASK_STACK_SIZE`         | 3584    | Often set much higher than needed |
| `CONFIG_ESP_SYSTEM_EVENT_TASK_STACK_SIZE` | 2304    | Often oversized                   |
| `CONFIG_ESP_TIMER_TASK_STACK_SIZE`        | 3584    |                                   |
| `CONFIG_LWIP_TCPIP_TASK_STACK_SIZE`       | 3072    |                                   |
| `CONFIG_FREERTOS_IDLE_TASK_STACKSIZE`     | 1536    |                                   |
| `CONFIG_FREERTOS_TIMER_TASK_STACK_DEPTH`  | 2048    |                                   |
| `CONFIG_MQTT_TASK_STACK_SIZE`             | varies  |                                   |

Warning: if stacks are too small, ESP-IDF crashes unpredictably — not always obviously a stack overflow.

### Heap optimization

- Analyze usage, remove unused mallocs, reduce sizes, free earlier
- lwIP: see `CONFIG_LWIP_*` minimum RAM options
- WiFi: reduce static/dynamic buffer counts (see WiFi Buffer Usage docs)
- Ethernet DMA: `CONFIG_ETH_DMA_BUFFER_SIZE`, `_RX_BUFFER_NUM`, `_TX_BUFFER_NUM`
- MbedTLS: see reducing heap usage docs
- BLE connections: `CONFIG_BTDM_CTRL_BLE_MAX_CONN`

### C/C++ code patterns for embedded

- Use const-correctness where it expresses the contract; flash placement depends on the target and linker.
- Measure allocation frequency and failure behavior before replacing standard-library types; hot-path allocation can affect latency and fragmentation, but fixed buffers also need capacity and concurrency analysis.
- Use bounded buffers only when the bound is justified, and check all truncation/error results.
- Check all `malloc`/`realloc`/`strdup` return values
- Free resources on all error paths

---

## Speed Optimization

### Flash access speed

- `CONFIG_ESPTOOLPY_FLASHFREQ=80m` — doubles default 40 MHz (verify HW support)
- `CONFIG_ESPTOOLPY_FLASHMODE=QIO` — nearly doubles DIO speed (verify flash chip + wiring)

### Compiler

- `CONFIG_COMPILER_OPTIMIZATION=O2` — best speed, increases binary size
- `CONFIG_COMPILER_OPTIMIZATION=Os` — good compromise (smaller + reasonably fast)
- Re-enable `-fjump-tables -ftree-switch-conversion` per source file for hot switch statements

### IRAM placement

Use `IRAM_ATTR` when the target's interrupt/cache contract requires code to run
while flash cache is unavailable, or when measurements on that SoC show a
worthwhile latency benefit. Ensure the complete reachable code and data are
accessible in that state. IRAM is limited; hot code is not automatically faster
there, and no duration cutoff applies universally.

### Arithmetic

- Benchmark arithmetic on the selected SoC; floating-point hardware support and performance vary across ESP32 families and toolchains.
- Prefer a representation that meets measured timing, precision, and code-size requirements.

### Logging

- Lower `CONFIG_LOG_DEFAULT_LEVEL` and `CONFIG_BOOTLOADER_LOG_LEVEL`
- Increase `CONFIG_ESP_CONSOLE_UART_BAUDRATE`
- Disable `CONFIG_LOG_DYNAMIC_LEVEL_CONTROL` — ~10x faster log calls
- Set low default level, high max level, then `esp_log_level_set()` at runtime for specific tags

### Task priorities (illustrative SDK reference only)

The values below are not application priorities. Verify the SDK version, target,
and task configuration; choose priorities and core affinity from scheduling and
latency requirements, and do not pin tasks to a core by default.

| Task            | Priority | Core |
| --------------- | -------- | ---- |
| WiFi Driver     | 23       | 0    |
| ESP Timer       | 22       | 0    |
| NimBLE Host     | 21       | 0    |
| Event Loop      | 20       | 0    |
| lwIP TCP/IP     | 18       | any  |
| Main (app_main) | 1        | 0    |

Tasks using a preemptive RTOS must avoid monopolizing execution; use that RTOS's
documented blocking/yield mechanisms where appropriate. Flash/cache behavior
during writes is target- and operation-specific; verify which tasks and
interrupts can continue before relying on it.

### Interrupts

- Select interrupt level and core according to the target's interrupt allocator and system scheduling constraints.
- Use `ESP_INTR_FLAG_IRAM` only when the handler must run during cache-disabled periods and all reachable code/data satisfy the target requirements.

### I/O performance

- Benchmark POSIX `read()`/`write()` against stdio `fread()`/`fwrite()` for the actual access pattern, libc, filesystem, and buffer size. Buffering can reduce system-call overhead; neither API is universally faster.
- Confirm the active libc and filesystem buffering configuration before changing it; use supported APIs such as `setvbuf()` or the applicable SDK option only when measurement justifies the tradeoff.

### Startup time

- Validation-skipping options trade integrity checks for time; change them only when the boot/recovery requirements permit the risk and the active SDK supports the option.
- Confirm timing effects for the actual boot path, chip, and configuration before changing clock, memory-test, or calibration settings.
- `CONFIG_RTC_CLK_CAL_CYCLES=0` — skip slow clock calibration
- `CONFIG_SPIRAM_MEMTEST=n` — saves ~1s per 4 MB PSRAM

---

## Binary Size Optimization

### Compiler & linker

- `CONFIG_COMPILER_OPTIMIZATION=Os` — optimize for size
- Assertion-level options change diagnostics and possibly checks. Do not silence or remove assertions solely for size: inspect the exact option, preserve checks required for safety/invariants, and make any release-only change part of the project's tested configuration.
- Disable exceptions or RTTI only when the project is designed, built, and tested without the corresponding features.
- Silent-check options can reduce diagnostic information; retain required error reporting and validate their exact semantics before use.
- Disable `CONFIG_ESP_ERR_TO_NAME_LOOKUP` — errors print as integers instead of strings

### Logging

- Lower `CONFIG_LOG_DEFAULT_LEVEL` (each level removes log strings from binary)
- Disable `CONFIG_LOG_DYNAMIC_LEVEL_CONTROL` — saves ~260B IRAM + ~264B DRAM + ~1KB flash

### C library

- Picolibc (`CONFIG_LIBC_PICOLIBC=y`) — up to 30 KB savings vs newlib; **default in ESP-IDF 6.x** (no longer experimental). `CONFIG_NEWLIB_NANO_FORMAT` is gone in IDF 6

### System

- Panic and assertion settings affect post-failure diagnostics and recovery. Follow project requirements; do not choose silent reboot or remove assertions solely to reduce size.

### Component-specific (disable if unused)

**WiFi:** `CONFIG_ESP_WIFI_ENABLE_WPA3_SAE`, `CONFIG_ESP_WIFI_SOFTAP_SUPPORT`, `CONFIG_ESP_WIFI_ENTERPRISE_SUPPORT`
**BLE NimBLE:** Reduce `CONFIG_BT_NIMBLE_MAX_CONNECTIONS` to 1, disable unused roles (`CENTRAL`, `OBSERVER`), lower `CONFIG_BT_NIMBLE_LOG_LEVEL`
**lwIP:** `CONFIG_LWIP_IPV6=n` if IPv4 only
**VFS:** `CONFIG_VFS_SUPPORT_TERMIOS=n` (~1.8KB), `CONFIG_VFS_SUPPORT_SELECT=n` (~2.7KB), `CONFIG_VFS_SUPPORT_DIR=n` (~0.5KB)
**MbedTLS:** Disable unused features: `SHA512_C`, `SHA3_C`, `SSL_ALPN`, `SSL_RENEGOTIATION`, `CCM_C`, `GCM_C`, `ECP_NIST_OPTIM`, `ERROR_STRINGS`, unused cipher suites and curves

---

## Example sdkconfig.defaults choices (not a drop-in template)

Use an option only if it exists for the selected SoC/ESP-IDF version and the
application, test, and diagnostic requirements allow its behavior. In
particular, do not disable exceptions, RTTI, logs, or assertions by default.

```ini
# Size-optimized build
CONFIG_COMPILER_OPTIMIZATION_SIZE=y

# Example only: keep required cache-off/ISR paths in accessible memory, and
# check this ESP-IDF release's documented tradeoffs before moving functions.
CONFIG_FREERTOS_PLACE_FUNCTIONS_INTO_FLASH=y
CONFIG_RINGBUF_PLACE_FUNCTIONS_INTO_FLASH=y
CONFIG_HEAP_PLACE_FUNCTION_INTO_FLASH=y

# Choose log levels from the project's diagnostic requirements.
CONFIG_LOG_DEFAULT_LEVEL=1
CONFIG_BOOTLOADER_LOG_LEVEL=1
CONFIG_LOG_DYNAMIC_LEVEL_CONTROL=n

# Only set these if the project is designed and tested without the features:
# CONFIG_COMPILER_CXX_EXCEPTIONS=n
# CONFIG_COMPILER_CXX_RTTI=n
```

---

## Verification after optimization

Use the target repository's documented build, test, and hardware-validation
workflow. Confirm the requested metric improved and relevant behavior, heap
headroom, and stack limits remain within project requirements. `pn mikro idf`
commands belong only to the mikrojs workspace.

---

## Historical mikrojs audit notes (only for that repository)

The status below was recorded in a June/August 2026 mikrojs audit. It is dated
project context, not current truth or general ESP-IDF guidance. Consult it only
when working in that repository, and verify the active branch, SDK, config, and
source before relying on any entry. Do not suppress checks or skip measurement
because an old audit says an optimization is already present.

The audit reported these settings and implementations at that time:

- `packages/@mikrojs/firmware/sdkconfig.defaults` (+ per-chip variants) already sets: `-Os`, exceptions/RTTI off, FreeRTOS/heap/ringbuf functions in flash, `ESP_WIFI_IRAM_OPT=n`, `ESP_WIFI_RX_IRAM_OPT=n`, log level NONE, `VFS_SUPPORT_SELECT=n`, `HAL_DEFAULT_ASSERTION_LEVEL=0`, TLS 1.3 off, `MBEDTLS_DYNAMIC_BUFFER=y`, `MBEDTLS_SSL_KEEP_PEER_CERTIFICATE=n`, CMN cert bundle, trimmed ECC curves/PKCS7/PEM/CRL/error strings, NimBLE peripheral+broadcaster only, WiFi static RX buffers reduced to 10.
- PSRAM: `CONFIG_SPIRAM=y` + `CONFIG_SPIRAM_USE_MALLOC=y` + `IGNORE_NOTFOUND` on esp32/s3/c5 variants. QuickJS heap goes to PSRAM via `CONFIG_MIKROJS_QUICKJS_HEAP_PSRAM` (Kconfig, default y if SPIRAM) → custom `JSMallocFunctions` in `packages/@mikrojs/native/src/mem.cpp` route to `heap_caps_malloc(MALLOC_CAP_SPIRAM)` with libc fallback.
- Runtime: `JS_NewRuntime2` with custom allocator; `JS_SetMemoryLimit(free_heap − app_config.mem_reserved)` and stack size = 2/3 of main task stack, both set in `mik_main.cpp` (~line 310). Context uses selective intrinsics (DOMException dropped, ~4.3 KB/runtime). Builtin bytecode lives in .rodata and deserializes lazily on first import. AbortController/Signal are lazy getters.
- WiFi and BLE both init lazily (on first JS use) and have full teardown paths; teardown currently only runs at runtime shutdown.

Items the audit listed as open gaps at that time (verify current status before acting):

1. ~~`JS_SetGCThreshold` is never called~~ **Fixed (June 2026)**: `mik__clamp_gc_threshold` in `mikrojs.cpp` caps the cycle-GC threshold at `mem_limit − mem_limit/8` at runtime creation, and `MIK_Loop` re-applies the cap each turn (QuickJS raises the threshold to 1.5× live size after every GC pass, which could push it back above the limit). Only affects cyclic garbage; refcounting frees acyclic garbage regardless. Regression tests in `test/oom_test.cpp`.
2. No build-time low-memory/no-BLE profile; `CONFIG_BT_ENABLED=y` in base defaults costs ~40-60 KB SRAM for apps that never use BLE (test build disables it as precedent).
3. No JS API to deinit WiFi (`esp_wifi_deinit`, ~50-65 KB) or BLE (`nimble_port_deinit`, ~30-50 KB) mid-session; teardown code exists but is only wired to shutdown.
4. HTTP task: 12 KB stack × up to 4 concurrent requests; header array realloc is unbounded (no max-header cap).
5. Untouched knobs worth measuring: `MBEDTLS_SSL_IN_CONTENT_LEN` (16384 → 8192 halves per-connection peak with DYNAMIC_BUFFER), `CONFIG_LIBC_LOCKS_PLACE_IN_IRAM=y` (default, could flip to n), `-flto` for QuickJS objects, `QJS_DISABLE_PARSER` for bytecode-only deployments (~50-100 KB flash).
6. `JS_READ_OBJ_ROM_DATA` is a no-op in QuickJS-NG (broken by inline caches) — flash-resident bytecode without heap copy needs an invasive patch; not worth it.

### August 2026 audit addendum (historical, mikrojs ESP32-C6)

The audit also reported these changes at that time:

- `ESP_WIFI_SLP_IRAM_OPT=n` (~19KB incl. its Kconfig selects — a hand-edited sdkconfig keeps
  the selected PM_SLEEP_FUNC_IN_IRAM/ESP_PERIPH_CTRL_FUNC_IN_IRAM/ESP_PHY_IRAM_OPT stale at y;
  only a defaults regen releases them) and `ESP_WIFI_EXTRA_IRAM_OPT=n` (6.8KB).
- `CONFIG_COMPILER_OPTIMIZATION_ASSERTIONS_SILENT=y` (7.7KB: DRAM strings for cache-off code
  plus assert call-site code in IRAM).
- Test-supervisor scratch (~3KB) and log-file buffers (~1.7KB) moved from BSS to
  conditional heap.
- The per-allocation size header in `mem.cpp` is gone on device: an optional
  `MIKPlatform.malloc_usable_size` hook (ESP32: `heap_caps_get_allocated_size`) replaced it,
  ~13KB across a loaded app. Consequence: QuickJS accounting (`memoryUsage().heapUsed`, heap
  baselines) now reports real rounded-up block sizes — slightly higher and mildly
  run-to-run variable; host builds keep the header scheme.
- Log-file flushes fsync (fflush alone never committed on LittleFS — flush='error'/'line' was
  not durable before this).

Census headline: ~160KB of the C6's 512KB SRAM is spent pre-heap (111.5KB IRAM text + 48KB
static DRAM at the old defaults). BLE controller = ~26KB IRAM even when never initialized
(lazy init only avoids heap); no lazy reclaim exists on C6 — `BT_RELEASE_IRAM` is
esp32c2-only — so the no-BLE saving (gap 2) is real RAM, not just flash, but needs a build
profile. WiFi static DRAM is another 21.7KB linked even if unused.

Measure with `packages/@mikrojs/native/test/memory_bench.cpp` (host) and `sys.memoryUsage()` / `mikro logs` on device.
