---

name: embedded-code-development
description: Implement embedded and firmware changes with deterministic behavior,
  explicit resource handling, hardware safety, and testable low-level code. Use when
  the story targets firmware, device drivers, RTOS tasks, timing-sensitive logic,
  or hardware-facing integrations.

---
## Purpose
Implement embedded and firmware changes with deterministic behavior, explicit resource handling, hardware safety, and testable low-level code.

## Activation rule
Use for authorized embedded implementation. Follow the target project's `AGENTS.md`, current contracts, toolchain, and hardware gates. The original bootstrap project's policy paths and story identifiers below apply only when that project actually supplies them. Model settings are configured by the runtime and user, not by this skill.

## Detailed workflow
1. Read the authorized task and existing requirements, architecture, timing/resource constraints, and hardware guidance. Use story artifacts only if the project maintains them.
2. Identify the hardware-facing contract and the failure modes before changing code.
3. Implement the smallest safe change with explicit state handling, bounded memory use, and clear error paths.
4. Add or update unit tests, simulation tests, hardware-abstraction tests, or diagnostic hooks as the project allows.
5. Document non-obvious timing, ownership, hardware assumptions, and public contracts using the project's existing conventions; do not add boilerplate comments to every function.
6. Update the project's relevant decision record when the authorized scope requires it, especially for interrupt behavior, polling vs event-driven choices, retries, power modes, or watchdog interactions.
7. Run the implementation feedback loop and repair failures.

## Embedded best practices
- Favor deterministic behavior and explicit state machines over implicit side effects.
- Keep interrupt handlers short and bounded; move heavier work into safe deferred contexts.
- Avoid uncontrolled dynamic allocation in constrained or safety-sensitive paths unless the project explicitly permits it.
- Document timing assumptions, concurrency/interrupt assumptions, and hardware register expectations.
- Fail safely: detect invalid hardware states, timeouts, and communication faults explicitly.
- Respect coding-guideline baselines such as MISRA-derived practices when the project or platform requires them.

### Resource management and memory safety
- **Explicit initialization:** All variables, buffers, and hardware contexts must be initialized before use.
- **No resource leaks:** Pair resource acquisition with guaranteed cleanup (file handles, DMA transfers, interrupts, memory).
- **C++ RAII pattern:** Use constructors/destructors or scoped guards for resource management (e.g., `std::lock_guard` for spinlocks).
- **C cleanup patterns:** Use `__attribute__((cleanup))` or explicit cleanup functions with clear ownership semantics.
- **Rust borrow checker:** Leverage ownership and lifetime rules to eliminate entire classes of resource bugs.
- **Memory profiling:** Use heap analyzers (e.g., Valgrind for simulation, IAR/STM32CubeIDE profilers for hardware) to detect memory leaks and fragmentation.

### Error handling strategies
- **Return codes pattern:** All functions that can fail return explicit status/error codes; caller **must** check before proceeding.
  ```c
  int result = sensor_init(&ctx);
  if (result != SENSOR_OK) {
      log_error("Sensor init failed: %d", result);
      return result;  // Propagate upward; do not continue.
  }
  ```
- **Assertions for invariants:** Follow the project's assertion and production fault policy. Removing diagnostics requires measured justification and must preserve required safety checks.
- **Status/error enums:** Define clear error codes (e.g., `TIMEOUT`, `INVALID_STATE`, `HW_ERROR`) and document what each means and how to recover.
- **ISR error reporting:** Use the project's verified ISR-safe queue, ring buffer, or handoff primitive for deferred reporting. Do not call a task logger or mutate a shared registry from an ISR without documented synchronization and bounded execution.
- **C++ exceptions:** Use exceptions in exception-safe embedded C++ (rare); document exception guarantees (strong, basic, no-throw) for every function.
- **Graceful degradation:** Identify which failures are recoverable (retry, reset peripheral) vs. fatal (halt, reboot, escalate to watchdog).

### Interrupt safety and concurrency
- **Minimize ISR scope:** ISRs must be both short and bounded; complex logic belongs in tasklets or RTOS tasks.
- **Atomic operations:** Use target-supported atomic operations or the project's verified critical-section primitives. C11 `stdatomic.h` and C++11 `std::atomic` apply only when the actual language/toolchain supports them and their implementation meets the ISR constraints; avoid composite check-then-act races.
- **Critical sections:** Protect shared data with spinlocks, mutexes (if RTOS allows), or interrupt disabling; document lock nesting levels.
- **Memory barriers:** Use the platform's documented atomics and compiler/CPU barriers where required. `volatile` alone provides neither a memory barrier nor inter-context synchronization.
- **Deadlock prevention:** Use timeout-based locks or non-blocking alternatives; never call blocking functions from ISRs.
- **Race condition testing:** Use stress tests, thread sanitizers (where applicable), and Helgrind (Valgrind) to expose race conditions in simulation.


## Failure modes to avoid
- Skipping static analysis or safety checks before marking firmware work as done.
- Implementing beyond the approved story scope without a scope-change decision.
- Ignoring resource constraints (memory, flash, stack) when adding new features.
- Committing debug or test instrumentation that should not ship in production firmware.

## Completion checklist
Use this checklist before marking embedded implementation work complete:
- [ ] **Story linked requirements and architecture reviewed** (understand the hardware contract and constraints).
- [ ] **Non-obvious assumptions and public contracts documented** using the project's conventions.
- [ ] **Every error path is handled explicitly** (no silent failures; all error codes checked).
- [ ] **All timeouts are bounded and documented** (no infinite loops or deadlocks; rationale in the existing authorized project record where applicable).
- [ ] **Interrupt handlers are minimal and bounded** (heavy work deferred to task/main context).
- [ ] **Shared data is protected** with documented platform synchronization; `volatile` alone is insufficient.
- [ ] **Resources are explicitly cleaned up** (no leaks of memory, file handles, DMA, or interrupts).
- [ ] **Hardware assumptions are documented** (timing, concurrency, register state, shared bus expectations).
- [ ] **Unit tests pass** (function-level tests in simulation with mocked hardware).
- [ ] **Applicable authorized integration checks recorded**; physical/HIL checks not performed remain explicitly pending, not implicitly passed.
- [ ] **Existing authorized project decision record updated where applicable**; mark not applicable when the project has no such record.
- [ ] **Code review checklist passed** (syntax and pattern review by another engineer).
- [ ] **Power and timing targets met or explicitly deferred** (profiling data attached if available).

## Guidelines lookup
- Follow `docs/guidelines/shared-operating-policy.md#guideline-lookup` for general guidance routing.
- If the project references **MISRA**, ISO 26262, DO-178C, or AUTOSAR, cross-reference this skill against those standards and document compliance.
- Check `docs/guidelines/small-change-fast-path.md` if the embedded change is isolated, low-risk, and doesn't affect hardware contracts.

## Story and artifact maintenance

Apply this section only when the project uses these artifact types. Update existing records within the authorized scope; do not create a parallel story or architecture system.
- Keep `US-*`, `HUS-*`, `BUG-*`, and `FEAT-*` items updated with implementation decisions (especially for interrupt behavior, polling cadence, retry logic, watchdog escalation).
- Link the story to tests: `TEST-*` for unit tests, `HIL-*` for hardware-in-the-loop, `PERF-*` for timing/power benchmarks.
- Update architecture records (ADR) if the embedded implementation changes hardware contracts or RTOS assumptions.
- Record any deferred work (e.g., "power profiling deferred to Phase 3") in the story so follow-up items don't get lost.

## Commands

These are illustrative commands for their named toolchains, not an instruction to introduce tools or flash hardware. Use actual project targets and authorized validation. Unexecuted physical checks remain pending; for Gauge record `NÃO EXECUTADO — GATE FÍSICO`. Sample polling periods, retry counts, watchdog policy, pin mappings, and synchronization below are not normative defaults.

### Compile and run unit tests (FreeRTOS + CMake example):
```bash
# 1. Build firmware in simulation or native environment.
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Debug -DENABLE_TESTS=ON ..
cmake --build .

# 2. Run unit tests with mocked hardware.
ctest --output-on-failure

# 3. (Optional) Run with Valgrind to detect memory leaks.
valgrind --leak-check=full --show-leak-kinds=all ./build/test_sensor_polling
```

### Run hardware-in-the-loop tests (with Segger J-Link / OpenOCD):
```bash
# 1. Flash firmware to board.
openocd -f interface/ftdi/ft2232h.cfg -f target/stm32f4x.cfg \
  -c "program build/firmware.elf verify reset exit"

# 2. Run HIL test suite (captures ISR counts, SPI traffic, etc.).
./hil_test_runner --task sensor_polling --duration 60 --output results.csv

# 3. Analyze results: check for timeouts, watchdog resets, power anomalies.
python3 scripts/analyze_hil_results.py results.csv
```

### Measure power and timing (oscilloscope / logic analyzer):
```bash
# 1. Trigger GPIO toggle during key operations (sensor read, ISR, error escalation).
#    See comments in sensor_polling_task() for GPIO_DEBUG_* macros.

# 2. Capture with logic analyzer:
#    - Sensor task: poll_begin → spi_read → poll_complete (measure 100ms period).
#    - SPI line: count transactions, detect timeout gaps.
#    - ISR count: verify ISR is not firing more than expected.
#    - Current: measure mA during idle vs. active polling.

# 3. Record in story:
#    - Polling overhead: X µA @ 100ms period.
#    - SPI transaction time: Y µs per read.
#    - Watchdog response time: Z ms after link fails.
```

## Function metadata standard
Follow the project's documentation conventions. If its bootstrap policy defines `docs/guidelines/shared-operating-policy.md#function-metadata-standard`, use it; otherwise the formats below are optional examples. Document meaningful preconditions, side effects, and safety assumptions without inventing story IDs or requiring boilerplate.

Example (C — Doxygen, blocking SPI read):
```c
/**
 * @brief Read the latest sensor sample over SPI.
 *
 * @details Performs a blocking SPI read operation. Safe to call from
 * main task context only.
 *
 * @param[in]  ctx    Sensor driver context (must be initialized via sensor_init()).
 * @param[out] sample Populated measurement structure on success.
 *
 * @return Status code: SENSOR_OK on success, SENSOR_TIMEOUT or
 *         SENSOR_HW_ERROR on failure.
 *
 * @pre  ctx is non-NULL and initialized.
 * @pre  SPI bus is not in use by another task.
 * @post sample is valid only if return value is SENSOR_OK.
 *
 * @note Blocks for up to SPI_TIMEOUT_MS milliseconds.
 * @note NOT safe to call from ISR context.
 *
 * @see  sensor_init(), sensor_sample_async()
 * @relates REQ-220 (Sensor Data Acquisition)
 *
 * Story: US-14 — Acquire periodic sensor readings
 */
sensor_status_t sensor_sample_read(sensor_ctx_t *ctx, sensor_sample_t *sample);
```

Example (Rust — `///` doc-comment, async read):
```rust
/// Reads the latest sensor sample over SPI asynchronously.
///
/// Schedules a non-blocking DMA transfer and awaits completion.
/// Safe to call from task context; must not be called from an ISR.
///
/// # Arguments
/// * `ctx` — Initialised sensor driver context.
///
/// # Returns
/// [`SensorSample`] on success, or a [`SensorError`] variant on timeout
/// or hardware failure.
///
/// # Panics
/// Panics in debug builds if `ctx` has not been initialised.
///
/// # Safety
/// Must not be called concurrently with [`sensor_reset`] on the same context.
///
/// Story: US-14 — Acquire periodic sensor readings
/// Requirement: REQ-220
pub async fn sensor_sample_read(ctx: &mut SensorCtx) -> Result<SensorSample, SensorError> {
```

## Worked example
### Example: watchdog-safe sensor polling task

**Design decision:** Implement a sensor polling task that runs every 100ms, detects sensor timeouts, and escalates to watchdog on repeated failures.

**ISR (interrupt handler) — minimal and bounded:**
```c
static volatile bool sensor_data_ready = false;

// Illustrative flag only: volatile is not synchronization and a bool can lose
// repeated events. Replace with the target's verified ISR-safe handoff when
// consuming from another context or when every event must be retained.

/**
 * @brief SPI data-ready interrupt handler.
 * 
 * Illustrative event publication only; no completion ISR is armed here.
 * The synchronous polling example below does not consume this flag.
 * An event-driven implementation needs its own verified handoff and consumer.
 */
void spi_irq_handler(void) {
    sensor_data_ready = true;
    // Do NOT call sensor_read_register() here—it can block.
    // Use the project's ISR-safe notification/queue and documented yield policy.
}
```

**Polling task — explicit error handling and state machine:**
```c
typedef enum {
    SENSOR_STATE_IDLE,
    SENSOR_STATE_READING,
    SENSOR_STATE_ERROR,
} sensor_polling_state_t;

static sensor_polling_state_t sensor_state = SENSOR_STATE_IDLE;
static uint8_t consecutive_errors = 0;
#define MAX_ERRORS_BEFORE_WATCHDOG 5

/**
 * @brief Sensor polling task (RTOS context).
 * 
 * Runs every 100ms (configured via FreeRTOS task delay).
 * Detects read timeouts and escalates to hardware watchdog after 5 consecutive failures.
 * 
 * @note This task is safe to call as it runs outside ISR context.
 */
void sensor_polling_task(void *arg) {
    sensor_ctx_t *ctx = (sensor_ctx_t *)arg;
    sensor_sample_t sample;
    sensor_status_t status;
    
    for (;;) {
        switch (sensor_state) {
            case SENSOR_STATE_IDLE:
                // Attempt to read sensor over SPI.
                sensor_state = SENSOR_STATE_READING;
                status = sensor_sample_read(ctx, &sample);  // Timeout: SPI_TIMEOUT_MS (50ms, << task period).
                
                if (status == SENSOR_OK) {
                    // Successful read; record sample and reset error counter.
                    log_info("Sensor sample: temp=%.2f, pressure=%.2f", sample.temp, sample.pressure);
                    consecutive_errors = 0;
                    sensor_state = SENSOR_STATE_IDLE;
                } else {
                    // Read failed; move to error state.
                    consecutive_errors++;
                    log_warn("Sensor read failed (attempt %d): status=%d", consecutive_errors, status);
                    sensor_state = SENSOR_STATE_ERROR;
                }
                break;
                
            case SENSOR_STATE_ERROR:
                // Decide recovery: retry immediately, delay, or escalate.
                if (consecutive_errors >= MAX_ERRORS_BEFORE_WATCHDOG) {
                    // Unrecoverable; escalate to watchdog.
                    log_error("Sensor: %d consecutive errors. Triggering watchdog.", consecutive_errors);
                    // Delegate safe outputs, task supervision, and reset policy
                    // to the project's established recovery flow. This helper
                    // is a placeholder, not a provided runtime implementation.
                    project_sensor_failure_recovery(ctx);
                    return;
                } else {
                    // Retry after exponential backoff (e.g., 100ms * 2^attempt, capped).
                    uint32_t backoff_ms = (1u << (consecutive_errors - 1)) * 100;
                    backoff_ms = (backoff_ms > 500) ? 500 : backoff_ms;
                    log_info("Sensor: retrying in %lu ms", backoff_ms);
                    vTaskDelay(pdMS_TO_TICKS(backoff_ms));
                    sensor_state = SENSOR_STATE_IDLE;
                }
                break;
        }
        
        // Periodic delay (100ms polling rate).
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}
```

**Recording the decision in the story:**
```
## Implementation Decision: Sensor Polling and Watchdog Escalation

- **Polling cadence:** 100ms rate chosen to balance freshness (< 200ms sensor latency req) with CPU load.
- **SPI timeout:** 50ms; if SPI read hangs > 50ms, abort and retry (< half the task period).
- **Error escalation:** 5 consecutive read failures triggers watchdog reset (unrecoverable hardware state).
- **Exponential backoff:** After first failure, wait 100ms; after second, 200ms, etc., capped at 500ms.
- **Why not polling:** Considered event-driven approach (interrupt on sensor ready); deferred due to sensor datasheet latency (up to 50ms jitter), making polling simpler.
- **Watchdog assumption:** A reset is guaranteed only if the actual watchdog is configured and its feeding/supervision policy stops feeding for this failure. Verify that policy; do not infer reset from a stalled task.
- **Future improvements:** Implement sensor health diagnostics (self-test register) before escalating to watchdog.

Linked artifacts:
- Architecture decision: ADR-008 (Sensor Polling vs. Event-Driven).
- Test plan: TEST-320 (Normal polling), TEST-321 (Timeout handling), TEST-322 (Watchdog escalation).
- Requirement: REQ-220 (Sensor Data Acquisition, < 200ms latency).
```

### Best-practice checklist for this example
- ✅ **ISR is minimal:** Only one flag write; no function calls or delays.
- ✅ **State machine is explicit:** Three clear states (IDLE, READING, ERROR) with documented transitions.
- ✅ **Error handling is explicit:** Every error code is checked; no implicit success assumptions.
- ✅ **Timeout is bounded:** SPI timeout (50ms) is much smaller than task period (100ms); no deadlock risk.
- ✅ **Escalation is clear:** 5 consecutive failures → watchdog; rationale documented.
- ✅ **Resource cleanup:** No dynamic allocation; no resource leaks.
- ✅ **Metadata is complete:** Functions document pre/post conditions, side effects, and linked tests.
- ✅ **Decision log is filled:** Story records "why" for polling cadence, backoff strategy, and watchdog choice.

## Code review checklist for embedded changes
Before committing embedded code:
- [ ] **Relevant function contracts and non-obvious assumptions documented** with existing project conventions.
- [ ] **No dynamic allocation in ISRs or safety-critical paths** (or justified + profiled).
- [ ] **All error codes are checked** before proceeding (no implicit success).
- [ ] **Timeouts are bounded** (no infinite loops; all blocking ops have timeout).
- [ ] **Interrupt nesting is safe** (ISRs don't call blocking functions; no nested locks without timeout).
- [ ] **Memory is initialized before use** (no uninitialized variables in structs or arrays).
- [ ] **Resource cleanup is paired with acquisition** (file handles, DMA, interrupts—all freed/disabled).
- [ ] **Hardware assumptions are documented** (e.g., "SPI bus is not shared with other tasks").
- [ ] **Tests are present** (unit tests, simulation tests, or hardware-in-the-loop).
- [ ] **Power/timing constraints are met or waived** (document if performance/power profiling deferred).
- [ ] **Existing authorized project decision record updated where applicable**; do not introduce a parallel story system.

## Testing embedded code
### Unit tests (simulation environment)
Test individual functions in isolation with mock hardware:
```c
void test_sensor_read_timeout(void) {
    // Mock SPI to return timeout after 50ms.
    mock_spi_set_timeout(50);
    
    sensor_ctx_t ctx = { .timeout_ms = 50 };
    sensor_sample_t sample;
    
    sensor_status_t status = sensor_sample_read(&ctx, &sample);
    
    assert(status == SENSOR_TIMEOUT);
    // Sample should be unchanged (verify with memcmp or value range).
}
```

### Hardware-in-the-loop (HIL) tests
Test real hardware interface:
- **Stimulus generation:** Use a logic analyzer or GPIO-controlled test rig to generate sensor signals (SPI pulses, interrupt edges).
- **Response validation:** Capture firmware behavior (register reads, ISR counts, task timing).
- **Failure injection:** Disconnect SPI, inject bit errors, clock glitches—verify graceful degradation.

### Stress and durability tests
- **Sustained polling:** Run sensor polling for hours; monitor for memory leaks, interrupt storms, or CPU throttling.
- **Failure cascades:** Simulate multiple sensor failures in sequence; verify escalation happens correctly.
- **Power profiling:** Measure current before/during/after polling; validate power targets.

## Hardware validation checklist
Before deploying to production:
- [ ] **Real hardware available and tested** (simulator often masks HW issues).
- [ ] **Pin assignments and timing verified** with actual hardware (layouts, pull-ups, clock distribution).
- [ ] **Interrupt latency measured** with a logic analyzer (verify ISR responds within deadline).
- [ ] **SPI/I2C bus collisions tested** if multiple masters share the bus.
- [ ] **Power rail stability confirmed** during high-current operations (e.g., radio TX during sensor read).
- [ ] **Thermal operation tested** (code runs at expected speed under worst-case temperature).
- [ ] **Watchdog reset confirmed** to work end-to-end (don't just assume the watchdog will fire).
- [ ] **Factory default recovery tested** (code can boot from clean slate if NVM is erased).

## Industry standards and guidelines
When defining safety or quality requirements:
- **MISRA-C:2012** — de facto standard for safety-critical embedded C; defines ~171 rules on type safety, resource leaks, concurrency, etc.
- **MISRA-C++:2008 (with AUTOSAR C++ updates)** — C++ equivalent; covers exception safety, template abuse, etc.
- **ISO 26262** (Functional Safety, automotive) — defines ASIL ratings, design patterns, V-model process for safety-critical systems.
- **IEC 61508** (Functional Safety, general) — framework for safety management; underpins ISO 26262 and IEC 61513 (nuclear).
- **DO-178C** (Avionics) — certification standard for airborne software; emphasizes traceability, testing, and independence of verification.
- **AUTOSAR** (AUTomotive Open System ARchitecture) — standardized APIs and patterns for automotive embedded systems.
- **FreeRTOS design patterns** — if using RTOS, follow FreeRTOS idioms (use semaphores, not raw flags; respect task priorities).
- **Google Embedded C++ Style Guide** — practical modern C++ rules for embedded (prefer `std::array` over raw arrays, use `static_assert` for compile-time checks).

If the story or architecture references a specific standard, audit the implementation against that standard and record the mapping in the decision log.
