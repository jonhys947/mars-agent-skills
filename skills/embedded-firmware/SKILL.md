---
name: embedded-firmware
description: >
  Embedded firmware and device-driver guidance for BSPs, peripherals, RTOS
  integration, and hardware validation. Use when a task concerns MCU firmware;
  follow the target project's silicon, architecture, toolchain, and contracts.
license: MIT
allowed-tools: Read, Write, Bash
metadata:
  version: 1.0.0
  author: chuanseng-ng
---

# Embedded Firmware & Device Drivers

## How to use this guidance

Use only the sections relevant to the requested firmware work. This is a set of
reference considerations, not a required stage sequence, sign-off workflow, or
artifact list. Follow the active project's instructions and toolchain; do not
assume an external orchestrator, agent, memory store, RTOS, or build system is
available.

Before editing, consult the target's existing requirements, board/SoC documentation,
startup code, build configuration, adjacent drivers, and tests as relevant. Do not
create run-state or memory files unless the project or user requests them.

## Purpose
Guide BSP creation, peripheral driver development, RTOS integration, and
system-level firmware validation. The firmware layer is the first software
to run on real silicon — correctness here enables all subsequent SW development.

---

## Example toolchains (choose from the target project)

These are examples, not a supported-tool mandate. Use the compiler, debugger,
simulator, vendor SDK, and version already selected by the project.

### Open-Source
- **GCC cross-compiler** (`arm-none-eabi-gcc`, `riscv64-unknown-elf-gcc`) — bare-metal firmware compilation
- **OpenOCD** (`openocd`) — open-source on-chip debugger; supports JTAG/SWD for bring-up
- **GDB cross-debugger** (`arm-none-eabi-gdb`) — source-level debugging over OpenOCD
- **QEMU** (`qemu-system-arm`, `qemu-system-riscv64`) — firmware validation before hardware is available

### Proprietary
- **J-Link GDB Server** (`JLinkGDBServer`, dialect `segger`) — high-speed JTAG/SWD probe from SEGGER
- **Lauterbach TRACE32** (`t32marm`, dialect `lauterbach`) — hardware trace and debug for bring-up
- **Arm Development Studio** (`armds`, dialect `arm`) — Eclipse-based IDE with Arm compiler and debugger

---

## BSP and startup considerations (when in scope)

Use the selected MCU's reference manual, vendor startup/SDK, linker script, ABI,
and the project's existing boot flow. If the project owns startup code, check
that reset/vector setup, stack selection, data initialization, clock setup, and
entry into application code follow that target's requirements. Reuse existing
device headers and linker symbols; do not require names such as `memory_map.h`,
`SystemInit()`, `__stack_top`, `crt0.S`, or a new startup file. Register access,
read-modify-write protection, barriers, and RTOS layering depend on the target
and register semantics.

Possible checks when applicable: vector validity and default exception handling,
clock readiness, initialized data and zeroed BSS, startup error paths, and
measured boot timing. These are checks to select from, not mandatory outputs.

Possible artifacts, only if requested or needed by the existing architecture:
startup/linker changes, board support code, build configuration, and focused
bring-up notes.

## Peripheral drivers

Follow existing project APIs and error conventions. Use the native result type
or a `void` operation where that is the established contract; do not introduce
a mandatory `status_t` or HAL signature. Bound waits when the operation can
otherwise hang and the contract allows a timeout. Document ownership and
concurrency where relevant. Add DMA, power hooks, or asynchronous callbacks only
when the selected peripheral, use case, and project API need them.

### Example validation coverage (only for peripherals/features in scope)
| Peripheral | Key Tests |
|------------|-----------|
| UART | Configured baud/parity, relevant TX/RX path, and DMA if used |
| SPI | Configured mode and relevant transfer path |
| I2C | Addressing and transaction patterns required by the device |
| GPIO | Configured input/output, pulls, and interrupts if used |
| Timer | The periodic, one-shot, PWM, or capture mode actually used |
| DMA | Only if the driver uses DMA: limits, completion, and error handling |
| Watchdog | Only if enabled: service and expected reset behavior |

Choose correctness, timing, coverage, and diagnostics criteria from the feature
contract and target requirements. Record only evidence requested by the task or
the project's normal workflow.

---

## RTOS integration (only when an RTOS change is requested)

Use the RTOS and port already selected by the project. Do not add a FreeRTOS or
Zephyr port, replace a scheduler, or change tick/heap/stack policy as a default
driver task. For a FreeRTOS target, confirm the port's interrupt priority rules,
task/stack units, allocator configuration, and ISR-safe APIs. Size stacks from
measured and analyzed peak paths plus the project's justified margin; use the
chosen RTOS's synchronization and priority-inheritance mechanisms when needed.
Validate only the scheduling and concurrency behavior relevant to the change.

---

## Driver validation (select checks relevant to the requested change)

Match validation to the feature, available test environment, and project gates.
The tiers below are examples; hardware access, overnight runs, and throughput
targets are not implied by loading this skill.

### Validation Tiers
| Level | Tests | Environment |
|-------|-------|-------------|
| Unit | Focused unit or host test | Where a suitable test double exists |
| Integration | Relevant interactions, such as DMA completion | Target or supported simulation |
| System | Requested end-to-end scenario | Project's supported environment |
| Stress | Workload and duration defined by the project | Only when required and available |

Use project-defined integration, power, reset, memory, timing, and acceptance
criteria when they are in scope. Do not invent duration or pass-rate gates.

## System integration and sign-off (project-defined)

For changes that affect multiple peripherals or system behavior, evaluate only
the interactions required by the task and existing requirements. Concurrency,
sleep/wake, warm/cold reset, memory tests, power measurements, and stress runs
are conditional on the design and its validation plan. Follow the project's
actual sign-off gates; a firmware skill does not authorize a hardware test,
publish a validated package, or declare a gate passed.

Record results in the project's expected location and format when requested.
Do not create persistent run-state or memory records by default, and report any
validation that was not performed.
