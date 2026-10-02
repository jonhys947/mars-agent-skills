# QUALITY_NOTES — embedded-cpp-guidelines

> Phase 2-D 일괄 세션에서 처리할 이슈를 기록한다.
> 이 파일은 병렬 세션에서 작성하고, 일괄 세션에서 반영 후 삭제한다.

---

## Phase 2-D에서 처리할 항목

### 1. skill-rules.json 등록 필요

`embedded-cpp-guidelines` 스킬을 `skill-rules.json`에 추가해야 한다.
YAML frontmatter의 `triggers` 필드는 참고용이며, 실제 자동 활성화는 `skill-rules.json`의
`promptTriggers.keywords`와 `intentPatterns`에 등록되어야 작동한다.

**추가할 항목 초안:**

```json
"embedded-cpp-guidelines": {
    "type": "domain",
    "enforcement": "suggest",
    "priority": "high",
    "description": "C++17 embedded systems: pure virtual HAL interfaces, RAII, lightweight Mock, Google Test + CMake FetchContent",
    "promptTriggers": {
        "keywords": [
            "embedded C++",
            "C++ firmware",
            "HAL interface",
            "embedded HAL",
            "pure virtual embedded",
            "RAII embedded",
            "IGpio",
            "IUart",
            "embedded unit test",
            "Google Test embedded",
            "CMake embedded",
            "STM32 C++",
            "MCU C++"
        ],
        "intentPatterns": [
            "(create|add|implement|write).*?(HAL|driver|interface|firmware)",
            "(embedded|MCU|STM32|Cortex).*?(C\\+\\+|class|interface)",
            "(unit test|test).*?(embedded|HAL|driver|mock)",
            "(RAII|resource management).*?(embedded|driver|GPIO)",
            "(CMake|FetchContent).*?(GoogleTest|gtest|embedded)"
        ]
    }
}
```

---

## 수정 완료 항목 (이번 세션에서 처리)

| 이슈 | 수정 내용 | 상태 |
|---|---|---|
| `platform/stm32/Gpio.hpp` 예시 `#pragma once` 누락 | 추가 완료 | ✅ |
| `IGpio` 이동 생성자/대입 연산자 삭제 미명시 | Rule of Five 명시 추가 | ✅ |
| STL 사용 환경 주의사항 누락 | MCU별 STL 지침 섹션 추가 | ✅ |
| **[P1]** 플랫폼 `Gpio` 생성자 `Gpio(uint32_t pin)` 오류 | `Gpio(uint8_t port, uint8_t pin)` + private 멤버 4개로 수정 | ✅ |
| **[P2.1]** `Led` 드라이버 `activeGpioLevel()`/`inactiveGpioLevel()` 헬퍼 누락 | 헤더 선언 + `.cpp` 구현 추가 (DRY 패턴 반영) | ✅ |
| **[P2.2]** `hal_drivers`에 플랫폼 스텁 소스 파일 누락 | `platform/stm32/Gpio.cpp`, `Uart.cpp` + include dir 추가 | ✅ |
| **[P2.3]** `tests/CMakeLists.txt` `enable_testing()` 누락 | CTest 통합 위해 추가 | ✅ |

---

*Last updated: 2026-03-05 (품질 점검 완료)*
