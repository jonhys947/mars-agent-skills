---
name: embedded-cpp-guidelines
description: Embedded C++ guidance for firmware, drivers, resource ownership, and tests. The examples use C++17, virtual HALs, RAII, handwritten mocks, Google Test, and CMake; follow the active project's language version, architecture, build, allocation, and test conventions.
metadata:
  triggers:
    - embedded C++
    - C++ firmware
    - HAL interface
    - embedded HAL
    - pure virtual embedded
    - RAII embedded
    - mock embedded
    - IGpio
    - IUart
    - embedded unit test
    - Google Test embedded
    - CMake embedded
    - STM32 C++
    - MCU C++
---

# Embedded C++ Guidelines

## Scope and project fit

The snippets mirror the upstream `base/cpp-embedded/` example, which is not bundled here. They illustrate one C++17/CMake/Google Test design; they do not require searching for that tree, upgrading a project's C++ standard, introducing CMake or a test dependency, adding a virtual HAL, or prohibiting allocation. First check the target's language/toolchain support, existing interfaces, resource lifecycle, allocator policy, and test runner. Apply only patterns that fit those constraints.

## 개요

C++17 임베디드 시스템에서 **플랫폼 이식성 + 단위 테스트 가능성**을 동시에 확보하기 위한 핵심 패턴.
하드웨어 없이 테스트 가능한 코드 구조를 목표로 한다.

원본 예제 위치: `base/cpp-embedded/` (이 skill과 함께 제공되지는 않음)

---

## 예제 1 — 순수 가상 HAL 인터페이스

**이 예제의 선택:** 하드웨어 접근을 순수 가상 인터페이스로 분리한다. Use this when the project benefits from runtime substitution or host-side tests and its ABI, code-size, and toolchain constraints permit virtual dispatch; a C API, templates, function table, or direct driver can be more suitable elsewhere.

```cpp
// include/hal/IGpio.hpp
#pragma once
#include <cstdint>

namespace hal {

class IGpio {
public:
    enum class Direction : uint8_t { Input, Output };
    enum class Level     : uint8_t { Low = 0, High = 1 };
    enum class PullMode  : uint8_t { None, PullUp, PullDown };

    virtual ~IGpio() = default;

    virtual void  setDirection(Direction dir)   noexcept = 0;
    virtual void  write(Level level)            noexcept = 0;
    [[nodiscard]]
    virtual Level read()                  const noexcept = 0;
    virtual void  toggle()                      noexcept = 0;
    virtual void  setPull(PullMode mode)        noexcept = 0;

protected:
    IGpio() = default;
    IGpio(const IGpio&)            = delete;  // 복사 금지
    IGpio& operator=(const IGpio&) = delete;
    IGpio(IGpio&&)                 = delete;  // 이동 금지 (명시적 Rule of Five)
    IGpio& operator=(IGpio&&)      = delete;
};

} // namespace hal
```

**핵심 규칙:**
- 소멸자는 반드시 `virtual ~IGpio() = default;`
- 모든 enum은 `enum class`로 타입 안전성 확보
- 읽기 전용 메서드는 `[[nodiscard]]` + `const noexcept`
- 인터페이스는 복사/대입 금지 (슬라이싱 방지)
- 네임스페이스: `hal::` (인터페이스), `platform::` (구현), `mock::` (테스트용)

**플랫폼 구현 — 스텁 구조 (실제 MCU 이식 시 본문만 교체):**

```cpp
// platform/stm32/Gpio.hpp
#pragma once
#include "../../include/hal/IGpio.hpp"

namespace platform::stm32 {

class Gpio final : public hal::IGpio {
public:
    // STM32 GPIO는 포트(A=0, B=1...) + 핀(0-15) 조합으로 식별
    explicit Gpio(uint8_t port, uint8_t pin) noexcept;
    ~Gpio() override = default;

    void  setDirection(Direction dir)   noexcept override;
    void  write(Level level)            noexcept override;
    Level read()                  const noexcept override;
    void  toggle()                      noexcept override;
    void  setPull(PullMode mode)        noexcept override;

private:
    uint8_t m_port;                   // GPIOx 포트 인덱스 (A=0, B=1, ...)
    uint8_t m_pin;                    // 핀 번호 (0–15)
    Level   m_level{Level::Low};      // 현재 출력 레벨 추적
    Direction m_direction{Direction::Output};
};

} // namespace platform::stm32
```

---

## 예제 2 — RAII 리소스 관리

**이 예제의 선택:** RAII expresses ownership for resources whose lifetime matches an object. Initialize hardware explicitly when construction cannot report failure or the contract requires a later activation step; perform destructor cleanup only when the hardware's documented safe state and lifetime rules allow it.

```cpp
// drivers/include/Led.hpp
#pragma once
#include "../../include/hal/IGpio.hpp"

namespace drivers {

class Led {
public:
    enum class ActiveLevel : uint8_t { High, Low };

    // 생성자: GPIO를 Output으로 초기화 + LED 소등
    explicit Led(hal::IGpio& gpio,
                 ActiveLevel activeLevel = ActiveLevel::High) noexcept;

    // 소멸자: 안전하게 소등 (항상 실행됨)
    ~Led() noexcept;

    // 복사/이동 금지 (GPIO 참조를 보유하므로)
    Led(const Led&)            = delete;
    Led& operator=(const Led&) = delete;
    Led(Led&&)                 = delete;
    Led& operator=(Led&&)      = delete;

    void on()     noexcept;
    void off()    noexcept;
    void toggle() noexcept;
    [[nodiscard]] bool isOn() const noexcept;

private:
    hal::IGpio& m_gpio;       // 의존성 주입 (참조, 소유하지 않음)
    ActiveLevel m_activeLevel;
    bool        m_isOn{false};

    // Active-high/low 로직 캡슐화 — on()/off() 내 중복 제거 (DRY)
    hal::IGpio::Level activeGpioLevel()   const noexcept;
    hal::IGpio::Level inactiveGpioLevel() const noexcept;
};

} // namespace drivers
```

```cpp
// drivers/src/Led.cpp
#include "../include/Led.hpp"

namespace drivers {

Led::Led(hal::IGpio& gpio, ActiveLevel activeLevel) noexcept
    : m_gpio{gpio}, m_activeLevel{activeLevel} {
    m_gpio.setDirection(hal::IGpio::Direction::Output);
    off();  // 초기 상태: 안전하게 소등
}

Led::~Led() noexcept {
    off();  // 소멸 시 반드시 소등
}

void Led::on()  noexcept { m_gpio.write(activeGpioLevel());   m_isOn = true;  }
void Led::off() noexcept { m_gpio.write(inactiveGpioLevel()); m_isOn = false; }
void Led::toggle() noexcept { m_isOn ? off() : on(); }
bool Led::isOn() const noexcept { return m_isOn; }

// ── 헬퍼: Active-high/low 로직을 한 곳에서 관리 (DRY) ─────────────────────
hal::IGpio::Level Led::activeGpioLevel() const noexcept {
    return (m_activeLevel == ActiveLevel::High)
           ? hal::IGpio::Level::High : hal::IGpio::Level::Low;
}
hal::IGpio::Level Led::inactiveGpioLevel() const noexcept {
    return (m_activeLevel == ActiveLevel::High)
           ? hal::IGpio::Level::Low : hal::IGpio::Level::High;
}

} // namespace drivers
```

**Ownership notes for this example:**
- The constructor initializes and the destructor turns the LED off only because this sample defines those lifecycle semantics; do not assume that every driver should touch hardware in a constructor or destructor.
- The injected `hal::IGpio&` is non-owning, so its lifetime must exceed the `Led` object's lifetime.
- Use the project's allocation policy. Static storage, stack storage, pools, and dynamic allocation each have constraints; choose based on boundedness, lifetime, concurrency, and failure handling rather than banning `new`/`delete` globally.

---

## 예제 3 — 경량 직접 작성 Mock 전략

This is one lightweight fake strategy for the interface shown above. Use the project's existing test doubles or framework when present; public counters are useful only when they expose the behavior a test needs to assert.

```cpp
// mock/MockGpio.hpp
#pragma once
#include "../include/hal/IGpio.hpp"

namespace mock {

class MockGpio final : public hal::IGpio {
public:
    // ── 호출 기록 (테스트에서 직접 접근) ─────────────────────────────────
    uint32_t  writeCount{0};
    uint32_t  toggleCount{0};
    Level     lastLevel{Level::Low};
    Direction lastDirection{Direction::Output};
    PullMode  lastPullMode{PullMode::None};

    // ── 입력 시뮬레이션 ───────────────────────────────────────────────────
    void setReadResponse(Level level) noexcept { m_readResponse = level; }

    // ── IGpio 구현 ────────────────────────────────────────────────────────
    void  setDirection(Direction dir)   noexcept override { lastDirection = dir; }
    void  write(Level level)            noexcept override { ++writeCount; lastLevel = level; }
    Level read()                  const noexcept override { return m_readResponse; }
    void  toggle()                      noexcept override {
        ++toggleCount;
        lastLevel = (lastLevel == Level::High) ? Level::Low : Level::High;
    }
    void  setPull(PullMode mode)        noexcept override { lastPullMode = mode; }

    // ── 리셋 (각 테스트 케이스 간 격리) ──────────────────────────────────
    void reset() noexcept {
        writeCount = toggleCount = 0;
        lastLevel     = Level::Low;
        lastDirection = Direction::Output;
        lastPullMode  = PullMode::None;
        m_readResponse = Level::Low;
    }

private:
    Level m_readResponse{Level::Low};
};

} // namespace mock
```

**Mock 테스트 패턴:**

```cpp
// tests/test_led_driver.cpp
#include <gtest/gtest.h>
#include "../mock/MockGpio.hpp"
#include "../drivers/include/Led.hpp"

TEST(LedDriverTest, Constructor_SetsOutput_AndOff) {
    mock::MockGpio gpio;
    drivers::Led led{gpio};  // 생성자에서 init

    EXPECT_EQ(gpio.lastDirection, hal::IGpio::Direction::Output);
    EXPECT_EQ(gpio.lastLevel,     hal::IGpio::Level::Low);
    EXPECT_FALSE(led.isOn());
}

TEST(LedDriverTest, Destructor_TurnsOffLed) {
    mock::MockGpio gpio;
    {
        drivers::Led led{gpio, drivers::Led::ActiveLevel::High};
        led.on();
        EXPECT_EQ(gpio.lastLevel, hal::IGpio::Level::High);
    }  // 스코프 종료 → 소멸자 호출

    EXPECT_EQ(gpio.lastLevel, hal::IGpio::Level::Low);  // 소멸자가 소등했는지 검증
}

TEST(LedDriverTest, Toggle_ActiveLow) {
    mock::MockGpio gpio;
    drivers::Led led{gpio, drivers::Led::ActiveLevel::Low};

    led.on();
    EXPECT_EQ(gpio.lastLevel, hal::IGpio::Level::Low);   // Active-low: 점등 = GPIO Low
    led.off();
    EXPECT_EQ(gpio.lastLevel, hal::IGpio::Level::High);  // 소등 = GPIO High
}
```

---

## Optional host-test example — CMake + Google Test FetchContent

This example uses CMake and Google Test for a host-side build. FetchContent downloads a dependency, so use it only when the repository permits network-fetched dependencies and this is its established build/test path; otherwise use the project's approved dependency and test setup.

```cmake
# CMakeLists.txt (루트)
cmake_minimum_required(VERSION 3.21)
project(CppEmbeddedBase LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# 경고 설정
if(MSVC)
    add_compile_options(/W4 /WX)
else()
    add_compile_options(-Wall -Wextra -Wpedantic -Werror)
endif()

# ── Google Test 자동 다운로드 ─────────────────────────────────────────────
include(FetchContent)
FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG        v1.14.0
)
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)  # Windows 정적 런타임
FetchContent_MakeAvailable(googletest)

# ── HAL 인터페이스 (헤더 전용) ────────────────────────────────────────────
add_library(hal_interfaces INTERFACE)
target_include_directories(hal_interfaces INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/include)
target_compile_features(hal_interfaces INTERFACE cxx_std_17)

# ── HAL 드라이버 (정적 라이브러리) ───────────────────────────────────────
add_library(hal_drivers STATIC
    drivers/src/Led.cpp
    drivers/src/Console.cpp
    platform/stm32/Gpio.cpp    # 플랫폼 스텁 — 실제 MCU 이식 시 교체
    platform/stm32/Uart.cpp
)
target_include_directories(hal_drivers PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/drivers/include
    ${CMAKE_CURRENT_SOURCE_DIR}/platform/stm32  # 스텁 헤더 포함 경로
)
target_link_libraries(hal_drivers PUBLIC hal_interfaces)

option(BUILD_TESTING "Build unit tests" ON)
if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
```

```cmake
# tests/CMakeLists.txt
enable_testing()  # CTest 통합 필수 — 누락 시 ctest 명령이 테스트를 찾지 못함

add_executable(run_tests
    test_gpio.cpp
    test_uart.cpp
    test_led_driver.cpp
)
target_include_directories(run_tests PRIVATE
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/mock
    ${CMAKE_SOURCE_DIR}/drivers/include
)
target_link_libraries(run_tests PRIVATE hal_drivers GTest::gtest_main)

include(GoogleTest)
gtest_discover_tests(run_tests)
```

**빌드 실행:**

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build
cd build && ctest --output-on-failure
```

---

## 디렉토리 구조

```
base/cpp-embedded/
├── include/hal/          ← 공개 인터페이스 (IGpio, IUart, ISpi, II2c)
├── platform/stm32/       ← 플랫폼 스텁 구현 (Gpio.cpp, Uart.cpp)
├── mock/                 ← 테스트용 Mock (MockGpio.hpp, MockUart.hpp)
├── drivers/              ← 재사용 드라이버 (Led, Console)
│   ├── include/
│   └── src/
├── tests/                ← Google Test 단위 테스트
├── examples/blinky/      ← Blinky 사용 예시
└── CMakeLists.txt
```

---

## Sample project conventions to evaluate

The table below describes choices made by the example scaffold, not universal embedded C++ rules. Follow the active project's coding standard, APIs, and constraints.

| 안티패턴 | 올바른 패턴 |
|---|---|
| `new` / `delete` 사용 | Follow the project's allocator and ownership rules; use fixed or pooled storage when its memory/timing requirements call for it |
| `HAL_GPIO_WritePin()` 직접 호출 | `IGpio::write()` 인터페이스 사용 |
| 함수 내부에서 `Gpio gpio;` 생성 | 생성자 매개변수로 `hal::IGpio&` 주입 |
| `int` 타입 GPIO 레벨 (`0`, `1`) | `enum class Level { Low, High }` |
| Google Mock `MOCK_METHOD` 매크로 | 직접 작성 Mock 클래스 (교육적, 경량) |
| `virtual` 소멸자 누락 | If polymorphic deletion through a base pointer is supported, define the appropriate virtual destructor |
| 예외(exception) 사용 | Follow the configured exception policy and project error convention; `noexcept` is a behavioral contract, not a universal replacement for exceptions |
| `std::cout` 디버그 출력 | `Console` 드라이버 (`IUart` 기반) 사용 |
| 플랫폼 헤더 비즈니스 로직에 포함 | HAL 인터페이스만 포함, 플랫폼 헤더 분리 |
| `enum` (타입 미약) | `enum class : uint8_t` |

---

## C++ features shown in the example

Use each feature only when the project's selected C++ standard, compiler/library, coding rules, and ABI support it.

```cpp
// ── C++11 features; use only if the selected standard/toolchain supports them ──
noexcept                // Declares a non-throwing function; use when it matches the contract
override                // Checks a virtual override
final                   // Prevents further derivation/overriding
constexpr               // Compile-time-capable declaration; exact rules vary by standard

// ── C++17 features; use only if the project enables C++17 ──────────────────
[[nodiscard]]           // C++17 standard attribute
[[maybe_unused]]        // C++17 standard attribute
if constexpr(...)       // C++17 compile-time branch

// ── Standard-library availability and behavior depend on the configured library ──
std::array<T, N>        // 고정 크기 배열 (malloc 대안, 대부분 MCU 지원)
std::optional<T>        // null 가능 반환값 (코드 크기 증가 가능)
std::string_view        // 문자열 참조 (동적 할당 없음, 읽기 전용)
// std::vector and std::string allocation behavior depends on the type/operation/library;
// check actual use and project memory policy instead of banning them by default.
```

> Check the exact C++ standard mode, standard library, compiler support, code-size and allocation characteristics, and any AUTOSAR/MISRA or project restrictions. MCU core family alone does not determine which library features are safe or available.

---

**Original example:** `base/cpp-embedded/` (not bundled here). The CMake, C++17, and Google Test versions above describe that sample setup only; confirm actual support and test results in the target repository.
