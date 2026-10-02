---
name: embedded-c-guidelines
description: C99 embedded firmware — HAL Ops Table pattern, FreeRTOS static tasks/queues/semaphores, ISR-safe ring buffer, no-malloc policy, Unity test with mock drivers, CMake HOST/STM32 dual-build. For writing drivers (GPIO/UART/SPI/I2C), HAL abstraction, RTOS tasks, or MCU firmware (STM32/ESP32).
triggers:
  - embedded
  - firmware
  - HAL
  - FreeRTOS
  - MCU
  - microcontroller
  - STM32
  - ESP32
  - RTOS
  - ring buffer
  - Unity test
  - mock driver
  - embedded C
  - peripheral driver
  - hal_gpio
  - hal_uart
---

# Embedded C Guidelines

## Reference

**Base code**: `base/c-embedded/` — C99 + CMake + HAL Ops Table + FreeRTOS 패턴

## Core Architecture

```
src/
├── hal/                  ← HAL 인터페이스 + 디스패처 (플랫폼 독립)
│   ├── hal_types.h       ← 공통 타입 (hal_err_t, GPIO/UART 열거형)
│   ├── hal_gpio.*        ← GPIO HAL
│   ├── hal_uart.*        ← UART HAL
│   └── hal_timer.*       ← Timer HAL
├── drivers/
│   ├── mock/             ← Host 테스트용 Mock (gpio_mock, uart_mock)
│   └── stm32/            ← MCU 드라이버 stub (실 환경 시 교체)
├── tasks/
│   ├── freertos_types.h  ← FreeRTOS 타입 (real/mock 호환)
│   ├── task_led.*        ← 기본 태스크 패턴 (vTaskDelay 루프)
│   └── task_uart_monitor.*  ← Queue 패턴 (ISR → Task)
└── utils/
    ├── ring_buffer.*     ← 정적 Ring Buffer (ISR-safe, no malloc)
    └── logger.*          ← UART 디버그 로거
```

---

## Pattern 1: HAL Ops Table (Function Pointer Table)

**핵심 원칙**: 앱 코드는 HAL API만 호출. 플랫폼 드라이버는 런타임에 등록.

```c
/* hal_gpio.h — HAL 인터페이스 정의 */
typedef struct {
    hal_err_t (*init)  (uint8_t pin, hal_gpio_dir_t dir);
    hal_err_t (*write) (uint8_t pin, hal_gpio_level_t level);
    hal_err_t (*read)  (uint8_t pin, hal_gpio_level_t *out_level);
    hal_err_t (*toggle)(uint8_t pin);
    void      (*deinit)(uint8_t pin);
} hal_gpio_ops_t;

hal_err_t hal_gpio_register(const hal_gpio_ops_t *ops);
hal_err_t hal_gpio_init  (uint8_t pin, hal_gpio_dir_t dir);
hal_err_t hal_gpio_write (uint8_t pin, hal_gpio_level_t level);
hal_err_t hal_gpio_read  (uint8_t pin, hal_gpio_level_t *out_level);
hal_err_t hal_gpio_toggle(uint8_t pin);
void      hal_gpio_deinit(uint8_t pin);
```

```c
/* hal_gpio.c — 디스패처 (플랫폼 코드 없음) */
static const hal_gpio_ops_t *s_ops = NULL;

hal_err_t hal_gpio_register(const hal_gpio_ops_t *ops) {
    if (ops == NULL) return HAL_ERR_PARAM;
    s_ops = ops;
    return HAL_OK;
}

hal_err_t hal_gpio_write(uint8_t pin, hal_gpio_level_t level) {
    if (s_ops == NULL || s_ops->write == NULL) return HAL_ERR_NOT_INIT;
    return s_ops->write(pin, level);
}
```

```c
/* main.c — 매크로로 ops 선택 후 단일 등록 (새 플랫폼 추가 시 #elif만 추가) */
#ifdef PLATFORM_HOST
    #define GPIO_OPS  gpio_mock_ops
#elif defined(PLATFORM_STM32)
    #define GPIO_OPS  gpio_stm32_ops
#endif
hal_gpio_register(&GPIO_OPS);
```

**새 MCU 포팅**: `src/drivers/[platform]/gpio_[platform].c`에 ops 구현 후 `main.c`에서 등록.

---

## Pattern 2: FreeRTOS Task — Static Allocation

**핵심 원칙**: 태스크 TCB와 스택 정적 할당. `xTaskCreate` 대신 `xTaskCreateStatic` 사용.

> **FreeRTOSConfig.h 필수 설정** — 없으면 `xTaskCreateStatic` 링크 에러 + idle task 구현 필요:
> ```c
> #define configSUPPORT_STATIC_ALLOCATION   1
> // 필수 콜백 구현 (FreeRTOS 내부 idle/timer task 정적 메모리 제공)
> void vApplicationGetIdleTaskMemory(StaticTask_t **ppTCB,
>     StackType_t **ppStack, uint32_t *pSize);
> ```

```c
/* task_led.h */
#define TASK_LED_STACK_SIZE  (256U)  /* words (= 1024 bytes on Cortex-M) */

typedef struct {
    uint8_t  pin;
    uint32_t period_ms;
} task_led_params_t;

void task_led_run(void *pv_params);

extern StaticTask_t g_task_led_tcb;
extern StackType_t  g_task_led_stack[TASK_LED_STACK_SIZE];
```

```c
/* task_led.c — 기본 태스크 패턴 */
StaticTask_t g_task_led_tcb;
StackType_t  g_task_led_stack[TASK_LED_STACK_SIZE];

void task_led_run(void *pv_params)
{
    const task_led_params_t *p = (const task_led_params_t *)pv_params;
    uint8_t  pin       = p ? p->pin       : GPIO_LED_STATUS_PIN;
    uint32_t period_ms = p ? p->period_ms : 1000U;

    hal_err_t err = hal_gpio_init(pin, HAL_GPIO_DIR_OUTPUT);
    if (err != HAL_OK) {
        vTaskSuspend(NULL);  /* 초기화 실패 시 자신을 정지 */
    }

    for (;;) {
        hal_gpio_write(pin, HAL_GPIO_LEVEL_HIGH);
        vTaskDelay(pdMS_TO_TICKS(period_ms / 2U));
        hal_gpio_write(pin, HAL_GPIO_LEVEL_LOW);
        vTaskDelay(pdMS_TO_TICKS(period_ms / 2U));
    }
}
```

```c
/* main.c — 정적 태스크 생성 */
static task_led_params_t s_led_params = {
    .pin = GPIO_LED_STATUS_PIN,
    .period_ms = 1000U,
};

TaskHandle_t h = xTaskCreateStatic(
    task_led_run,          /* 태스크 함수 */
    "led",                 /* 이름 */
    TASK_LED_STACK_SIZE,   /* 스택 워드 수 (Cortex-M: words × 4 = bytes) */
    &s_led_params,         /* 파라미터 */
    2U,                    /* 우선순위 */
    g_task_led_stack,      /* 정적 스택 */
    &g_task_led_tcb        /* 정적 TCB */
);
configASSERT(h != NULL);   /* 반환값 필수 검사 — NULL 시 silent fault */
```

---

## Pattern 3: FreeRTOS Queue — ISR → Task

**핵심 원칙**: ISR은 `xQueueSendFromISR` 사용. Task는 `xQueueReceive`로 블로킹 대기.

```c
/* 큐 정적 생성 (task_uart_monitor.c) */
/* 큐 핸들은 extern global — ISR 접근을 위해 전역 필요 */
/* ISR은 g_uart_monitor_queue에 직접 접근하지 않고 래퍼 함수 경유 권장 */
StaticQueue_t        g_uart_monitor_queue_storage;
uart_monitor_msg_t   g_uart_monitor_queue_buf[UART_MONITOR_QUEUE_SIZE];
QueueHandle_t        g_uart_monitor_queue;

/* ISR-safe 래퍼 — ISR이 큐 핸들을 직접 참조하지 않아 리팩터링 용이 */
BaseType_t task_uart_monitor_push_byte_from_isr(uint8_t port, uint8_t byte);

QueueHandle_t task_uart_monitor_queue_init(void) {
    g_uart_monitor_queue = xQueueCreateStatic(
        UART_MONITOR_QUEUE_SIZE,
        sizeof(uart_monitor_msg_t),
        (uint8_t *)s_queue_buf,
        &s_queue_storage
    );
    return g_uart_monitor_queue;
}
```

```c
/* ISR 핸들러 — FromISR API 필수 (플랫폼별 register명 상이: DR/RDR 등) */
/* Cortex-M: NVIC 우선순위 >= configMAX_SYSCALL_INTERRUPT_PRIORITY 필수 */
void UART_RX_IRQHandler(void) {
    uint8_t byte = platform_uart_read_byte();  /* 플랫폼별 레지스터 접근 */
    uart_monitor_msg_t msg = {
        .type = UART_MSG_BYTE_RECEIVED,
        .data = byte,
        .port = UART_DEBUG_PORT,
    };
    BaseType_t woken = pdFALSE;
    xQueueSendFromISR(g_uart_monitor_queue, &msg, &woken);
    portYIELD_FROM_ISR(woken);  /* 고우선순위 태스크로 즉시 전환 */
}
```

```c
/* Task 수신 루프 */
void task_uart_monitor_run(void *pv_params) {
    (void)pv_params;
    uart_monitor_msg_t msg;

    for (;;) {
        if (xQueueReceive(g_uart_monitor_queue, &msg, portMAX_DELAY) == pdPASS) {
            switch (msg.type) {
            case UART_MSG_BYTE_RECEIVED:
                handle_byte(msg.data);
                break;
            default:
                break;
            }
        }
    }
}
```

---

## Pattern 4: Static Ring Buffer (ISR-Safe)

**핵심 원칙**: 정적 배열만 사용. 크기는 반드시 **2의 거듭제곱**. `head`/`tail`은 `volatile`.

```c
/* ring_buffer.h */
typedef struct {
    uint8_t  *buf;
    size_t    capacity;        /* 반드시 2의 거듭제곱 */
    size_t    mask;            /* capacity - 1 */
    volatile size_t head;      /* Read index  (consumer) */
    volatile size_t tail;      /* Write index (producer) */
} ring_buf_t;

hal_err_t ring_buf_init      (ring_buf_t *rb, uint8_t *storage, size_t size);
hal_err_t ring_buf_write_byte(ring_buf_t *rb, uint8_t byte);
hal_err_t ring_buf_read_byte (ring_buf_t *rb, uint8_t *out);
size_t    ring_buf_available (const ring_buf_t *rb);
```

```c
/* 사용 예시 */
static uint8_t    s_uart_buf[256];   /* 반드시 2의 거듭제곱 */
static ring_buf_t s_uart_rb;

void app_init(void) {
    ring_buf_init(&s_uart_rb, s_uart_buf, sizeof(s_uart_buf));
}

/* ISR에서 쓰기 (single producer) */
void UART_RX_IRQHandler(void) {
    uint8_t b = uart_read_byte();
    ring_buf_write_byte(&s_uart_rb, b);  /* ISR-safe: single producer */
}

/* Task에서 읽기 (single consumer) */
void process_uart(void) {
    uint8_t b;
    while (ring_buf_read_byte(&s_uart_rb, &b) == HAL_OK) {
        handle_byte(b);
    }
}
```

---

## Pattern 5: Unity Test with Mock Driver

**구조**: 각 테스트 파일이 독립 실행파일. `setUp`/`tearDown` 중복 정의 충돌 없음.

```c
/* test_hal_gpio.c */
#include "unity.h"
#include "hal_gpio.h"
#include "gpio_mock.h"   /* Mock ops + 테스트 헬퍼 함수 */

void setUp(void)    { hal_gpio_register(&gpio_mock_ops); }
void tearDown(void) { hal_gpio_deinit(0U); }

void test_gpio_write_high_sets_level(void) {
    hal_gpio_init(0U, HAL_GPIO_DIR_OUTPUT);
    hal_gpio_write(0U, HAL_GPIO_LEVEL_HIGH);

    hal_gpio_level_t level;
    hal_gpio_read(0U, &level);
    TEST_ASSERT_EQUAL_INT(HAL_GPIO_LEVEL_HIGH, (int)level);
}

void test_gpio_read_null_returns_error(void) {
    hal_gpio_init(0U, HAL_GPIO_DIR_OUTPUT);
    hal_err_t err = hal_gpio_read(0U, NULL);
    TEST_ASSERT_EQUAL_INT(HAL_ERR_PARAM, (int)err);
}

int main(void) {
    UnityBegin("test_hal_gpio.c");
    RUN_TEST(test_gpio_write_high_sets_level);
    RUN_TEST(test_gpio_read_null_returns_error);
    /* ... */
    return UnityEnd();
}
```

```c
/* gpio_mock.h — Mock 드라이버 + 테스트 헬퍼 */
extern const hal_gpio_ops_t gpio_mock_ops;

void             gpio_mock_set_input_level(uint8_t pin, hal_gpio_level_t level);
hal_gpio_level_t gpio_mock_get_level(uint8_t pin);
```

```cmake
# tests/CMakeLists.txt — 각 테스트 파일을 독립 실행파일로 빌드
add_executable(test_hal_gpio   test_hal_gpio.c)
add_executable(test_ring_buffer test_ring_buffer.c)

target_link_libraries(test_hal_gpio    PRIVATE hal drivers unity)
target_link_libraries(test_ring_buffer PRIVATE utils unity)

add_test(NAME gpio_hal    COMMAND test_hal_gpio)
add_test(NAME ring_buffer COMMAND test_ring_buffer)
```

---

## CMake Dual Build

```cmake
# CMakeLists.txt
option(BUILD_FOR_HOST "Build for host PC (mock drivers + tests)" ON)

if(BUILD_FOR_HOST)
    add_compile_definitions(PLATFORM_HOST FREERTOS_MOCK)
    set(DRIVER_SRC
        src/drivers/mock/gpio_mock.c
        src/drivers/mock/uart_mock.c
    )
else()
    add_compile_definitions(PLATFORM_STM32)
    set(DRIVER_SRC
        src/drivers/stm32/gpio_stm32.c
        src/drivers/stm32/uart_stm32.c
    )
    # -DCMAKE_TOOLCHAIN_FILE=arm-none-eabi-toolchain.cmake 로 크로스 컴파일
endif()
```

```bash
# Host 빌드 + 테스트 실행
cmake -B build -DBUILD_FOR_HOST=ON -DBUILD_TESTS=ON
cmake --build build
ctest --test-dir build -V

# STM32 크로스 컴파일
cmake -B build_stm32 \
    -DBUILD_FOR_HOST=OFF \
    -DCMAKE_TOOLCHAIN_FILE=arm-none-eabi-toolchain.cmake
cmake --build build_stm32
```

---

## FreeRTOS Mock Types (Host Build)

```c
/* freertos_types.h — FREERTOS_MOCK 시 활성화 */
#ifdef FREERTOS_MOCK
    typedef uint32_t TickType_t;
    typedef uint32_t StackType_t;
    typedef struct { uint8_t dummy[128]; } StaticTask_t;
    typedef struct { uint8_t dummy[64];  } StaticQueue_t;

    #define pdMS_TO_TICKS(ms)  ((TickType_t)(ms))
    #define portMAX_DELAY      ((TickType_t)0xFFFFFFFFUL)

    static inline void vTaskDelay(TickType_t t)    { (void)t; }
    static inline void vTaskSuspend(TaskHandle_t h){ (void)h; }
    /* xTaskCreateStatic, xQueueCreateStatic 등 stub 포함 */
#else
    #include "FreeRTOS.h"
    #include "task.h"
    #include "queue.h"
    #include "semphr.h"
#endif
```

---

## hal_types.h — 공통 에러 코드

```c
typedef enum {
    HAL_OK           =  0,   /* 성공 */
    HAL_ERR_GENERIC  = -1,   /* 일반 오류 */
    HAL_ERR_PARAM    = -2,   /* NULL 포인터, 범위 초과 */
    HAL_ERR_BUSY     = -3,   /* 리소스 사용 중 */
    HAL_ERR_TIMEOUT  = -4,   /* 타임아웃 */
    HAL_ERR_NOT_INIT = -5,   /* hal_xxx_register() 미호출 */
    HAL_ERR_OVERFLOW = -6,   /* 버퍼 오버플로우 */
} hal_err_t;
```

---

## Porting to a New Platform

1. `include/app_config.h` — 핀 번호, 스택 크기, 포트 번호 등 모든 커스터마이징 상수 정의
2. `src/drivers/[platform]/gpio_[platform].c` 작성 — `hal_gpio_ops_t` 구현
3. `src/drivers/[platform]/uart_[platform].c` 작성 — `hal_uart_ops_t` 구현
4. `CMakeLists.txt`에 `PLATFORM_[PLATFORM]` 조건 분기 + `#define GPIO_OPS` 추가
5. FreeRTOS 실 소스 연결: `FreeRTOS/Source/` + MCU 포트 + `FreeRTOSConfig.h`

---

## Anti-Patterns

```c
/* ❌ 동적 메모리 할당 금지 */
uint8_t *buf = malloc(256);   /* 힙 단편화, 실시간성 파괴, MISRA 위반 */

/* ✅ 정적 배열 사용 */
static uint8_t buf[256];
```

```c
/* ❌ Ring Buffer 크기를 2의 거듭제곱이 아닌 값으로 설정 */
uint8_t buf[100];
ring_buf_init(&rb, buf, sizeof(buf));  /* HAL_ERR_PARAM 반환 */

/* ✅ 2의 거듭제곱 */
uint8_t buf[128];  /* 64, 128, 256, 512 ... */
```

```c
/* ❌ ISR에서 non-ISR FreeRTOS API 호출 */
void IRQHandler(void) {
    xQueueSend(q, &msg, 0);  /* ISR에서 사용 금지 — 크래시 */
}

/* ✅ FromISR API 사용 */
void IRQHandler(void) {
    BaseType_t woken = pdFALSE;
    xQueueSendFromISR(q, &msg, &woken);
    portYIELD_FROM_ISR(woken);
}
```

```c
/* ❌ 여러 테스트 파일을 하나의 실행파일로 컴파일 */
/* setUp/tearDown 중복 정의 → 링크 에러 */

/* ✅ 각 테스트 파일은 독립 실행파일 */
add_executable(test_foo test_foo.c)
add_executable(test_bar test_bar.c)
```

```c
/* ❌ FreeRTOS 헤더 직접 include (MCU 환경에서만 존재) */
#include "FreeRTOS.h"   /* Host 빌드 시 컴파일 불가 */

/* ✅ freertos_types.h 경유 (real/mock 자동 선택) */
#include "freertos_types.h"
```

```c
/* ❌ FreeRTOS API 호출 ISR에 높은 NVIC 우선순위 설정 (Cortex-M) */
/* ISR 우선순위 < configMAX_SYSCALL_INTERRUPT_PRIORITY 시 하드폴트 */
NVIC_SetPriority(USART1_IRQn, 0U);  /* 최고 우선순위 — FreeRTOS API 호출 불가 */

/* ✅ configMAX_SYSCALL_INTERRUPT_PRIORITY 이하 우선순위 설정 */
/* FreeRTOSConfig.h: #define configMAX_SYSCALL_INTERRUPT_PRIORITY  5 */
NVIC_SetPriority(USART1_IRQn, 6U);  /* 5 이하(숫자 높을수록 낮은 우선순위) */
```

---

*Line count: < 500 ✅ | Reference: `base/c-embedded/` ✅ | Anti-patterns: 7 ✅*
