---
name: esp32-development
description: ESP32 memory management, ISRs, FreeRTOS tasks, SPI, power management, ESPHome components. Use when writing ESP32 code, handling interrupts, managing memory, configuring SPI, or implementing ESPHome components.
---

# ESP32 Development Best Practices

Examples below cover different framework paths. Check the actual ESP32 SoC/module, board, ESP-IDF or Arduino core version, and whether the project uses ESPHome before applying one. Memory sizes, DMA capabilities, pins, ISR placement, task/core APIs, wake sources, and persistence behavior vary by target and framework; this skill does not select hardware bindings or introduce a framework.

**Sources:**
- [ESP-IDF Programming Guide](https://docs.espressif.com/projects/esp-idf/en/stable/esp32/)
- [Arduino-ESP32 Documentation](https://docs.espressif.com/projects/arduino-esp32/en/latest/)
- [ESPHome Developer Guide](https://esphome.io/guides/)

---

## Memory Architecture

### Memory Types

| Type | Size | Use For | Access |
|------|------|---------|--------|
| **Internal RAM** | Varies by SoC/configuration | Data, stacks, and executable code | Check linker regions, capability flags, and cache behavior |
| **Flash-mapped code/data** | Varies by module/configuration | Code or read-only data through cache | Not necessarily accessible during cache-disabled intervals |
| **External PSRAM** | Optional; varies by board/configuration | Larger noncritical data pools | Not automatically DMA-capable or interchangeable with internal RAM |
| **RTC/retention memory** | Varies by SoC | Data retained across supported sleep/reset modes | Confirm retention and wake semantics for the target |

Use the selected chip's memory map and build map file rather than fixed ESP32-family capacities.

### Memory Placement Attributes

```cpp
// ESP-IDF example only. Use an IRAM attribute when the target's cache/ISR
// contract requires it, and ensure callees and data are also accessible.
void IRAM_ATTR my_isr_handler() {
  // Critical timing code
}

// Place data in RTC memory (survives deep sleep)
RTC_DATA_ATTR int boot_count = 0;

// Example attributes; verify the selected peripheral's DMA memory contract.
DMA_ATTR uint8_t dma_buffer[256];

// Example only; use the exact alignment required by the target/API.
WORD_ALIGNED_ATTR uint8_t aligned_buf[64];
```

### Stack Considerations

```cpp
// Example risk: a local object's size must fit this task's analyzed stack budget.
void process() {
  uint8_t buffer[8192];  // Risk of stack overflow!
}

// Possible alternative only if heap placement, ownership, failure handling,
// lifetime, and concurrent calls fit the project design.
void process() {
  auto buffer = std::make_unique<std::array<uint8_t, 8192>>();
}

// Possible alternative when a single shared lifetime and concurrency policy fit.
void process() {
  static uint8_t buffer[8192];  // One instance, not on stack
}
```

---

## Interrupt Handling (ISR)

### ISR Rules

1. Keep interrupt work bounded and defer noncritical processing when the architecture permits.
2. Place handlers in IRAM only when required by the selected ESP-IDF interrupt/cache configuration; verify all reachable code and data.
3. Do not block in an ISR. Use only APIs documented as safe for the selected interrupt context.
4. Choose synchronization supported by the compiler, core, and ISR context; verify atomic lock-free behavior and alignment before using `std::atomic` in an ISR.

### ISR Flag Pattern (example; verify target support)

Use `std::atomic<bool>` with `.exchange()` to avoid the read-clear race condition:

```cpp
#include <atomic>

std::atomic<bool> data_ready{false};

void IRAM_ATTR gpio_isr_handler(void* arg) {
  data_ready.store(true, std::memory_order_release);
}

void loop() {
  // Atomic read-and-clear — no race condition
  if (data_ready.exchange(false, std::memory_order_acquire)) {
    process_data();
  }
}
```

### Multi-byte Atomics

```cpp
std::atomic<uint32_t> counter{0};

void IRAM_ATTR isr() {
  counter.fetch_add(1, std::memory_order_relaxed);
}

void loop() {
  uint32_t val = counter.load(std::memory_order_acquire);
  // Use val...
}
```

**Note:** Atomic lock-free support is compiler-, type-, core-, and ABI-dependent. Verify the actual toolchain and ISR behavior; do not infer it from the ESP32 name alone.

---

## FreeRTOS Task Management (only for FreeRTOS projects)

### Task Creation

```cpp
// Create task with adequate stack
TaskHandle_t task_handle;
xTaskCreate(
    task_function,      // Function
    "TaskName",         // Name (for debugging)
    4096,               // Stack size in bytes
    nullptr,            // Parameters
    5,                  // Priority (higher = more important)
    &task_handle        // Handle
);

// Optional affinity example for a multi-core target. Many ESP32 variants or
// project configurations have different core availability and scheduling needs.
xTaskCreatePinnedToCore(
    task_function, "TaskName", 4096, nullptr, 5, &task_handle,
    1  // Core ID: 0 or 1
);
```

### Task Communication

```cpp
// Queue for ISR to task communication
QueueHandle_t event_queue;
event_queue = xQueueCreate(10, sizeof(Event));

// From ISR
void IRAM_ATTR isr() {
  Event e = {.type = EVENT_DATA};
  BaseType_t woken = pdFALSE;
  xQueueSendFromISR(event_queue, &e, &woken);
  if (woken) portYIELD_FROM_ISR();
}

// In task
void task(void* param) {
  Event e;
  while (true) {
    if (xQueueReceive(event_queue, &e, portMAX_DELAY)) {
      handle_event(e);
    }
  }
}
```

### Synchronization

```cpp
// Mutex for shared resource protection
SemaphoreHandle_t mutex = xSemaphoreCreateMutex();

void access_shared() {
  if (xSemaphoreTake(mutex, pdMS_TO_TICKS(100))) {
    // Access shared resource
    xSemaphoreGive(mutex);
  }
}

// Binary semaphore for signaling
SemaphoreHandle_t signal = xSemaphoreCreateBinary();

void IRAM_ATTR isr() {
  BaseType_t woken = pdFALSE;
  xSemaphoreGiveFromISR(signal, &woken);
  if (woken) portYIELD_FROM_ISR();
}
```

---

## GPIO Best Practices

### Configuration

```cpp
// ESP-IDF style
gpio_config_t io_conf = {
    .pin_bit_mask = (1ULL << GPIO_NUM_4),
    .mode = GPIO_MODE_OUTPUT,
    .pull_up_en = GPIO_PULLUP_DISABLE,
    .pull_down_en = GPIO_PULLDOWN_DISABLE,
    .intr_type = GPIO_INTR_DISABLE,
};
gpio_config(&io_conf);

// Arduino style
pinMode(4, OUTPUT);
pinMode(5, INPUT_PULLUP);
// Example numbers only: use the project/board's approved pin assignment.
```

### Strapping Pins (example list is classic ESP32 only)

Never use the table below to assign pins on another ESP32 SoC or board. Check
the target datasheet, module documentation, schematic, and project pin contract.

| GPIO | Function | Safe to Use? |
|------|----------|--------------|
| GPIO0 | Boot mode | Avoid (needs HIGH at boot) |
| GPIO2 | Boot mode | Use with care |
| GPIO5 | SDIO timing | Use with care |
| GPIO12 | Flash voltage | Avoid |
| GPIO15 | SDIO timing | Use with care |

---

## SPI Communication

### Best Practices

```cpp
// Use hardware CS when possible
spi_device_interface_config_t devcfg = {
    .mode = 0,
    .clock_speed_hz = 1000000,
    .spics_io_num = CS_PIN,  // Hardware CS
    .queue_size = 7,
};

// For software CS, use RAII pattern
class SpiTransaction {
 public:
  explicit SpiTransaction(int cs_pin) : cs_(cs_pin) {
    gpio_set_level((gpio_num_t)cs_, 0);
  }
  ~SpiTransaction() {
    gpio_set_level((gpio_num_t)cs_, 1);
  }
 private:
  int cs_;
};

// DMA for large transfers
spi_bus_config_t buscfg = {
    .mosi_io_num = MOSI_PIN,
    .miso_io_num = MISO_PIN,
    .sclk_io_num = SCLK_PIN,
    .max_transfer_sz = 4096,  // Example only; use the SDK/peripheral's supported limit
};
```

### Timing

```cpp
// Add delays after SPI operations if needed
void write_register(uint8_t addr, uint8_t data) {
  {
    SpiTransaction txn(cs_pin_);
    spi_->transfer(addr);
    spi_->transfer(data);
  }
  // Wait only as required by the selected device datasheet/driver contract.
  delayMicroseconds(15);  // Illustrative value, not a general SPI delay
}
```

---

## Power Management

### Sleep Modes

| Mode | Wake Sources | Current | Use Case |
|------|-------------|---------|----------|
| Modem sleep | WiFi beacon | Varies by SoC, board, and configuration | Connected idle |
| Light sleep | Supported wake sources vary | Varies by SoC, board, and configuration | Short idle periods |
| Deep sleep | Supported wake sources vary | Varies by SoC, board, and configuration | Long idle periods |

### Deep Sleep Pattern (ESP-IDF example; verify SoC wake-source support)

```cpp
#include "esp_sleep.h"

RTC_DATA_ATTR int boot_count = 0;

void setup() {
  boot_count++;

  // Configure wake sources
  esp_sleep_enable_timer_wakeup(60 * 1000000);  // 60 seconds
  esp_sleep_enable_ext0_wakeup(GPIO_NUM_33, 0); // GPIO wake

  // Do work...

  // Enter deep sleep
  esp_deep_sleep_start();
}
```

---

## WiFi Best Practices

### Connection Management (Arduino-ESP32 example)

```cpp
// Use event-driven connection handling
WiFi.onEvent([](WiFiEvent_t event) {
  switch (event) {
    case WIFI_EVENT_STA_CONNECTED:
      ESP_LOGI(TAG, "Connected to AP");
      break;
    case WIFI_EVENT_STA_DISCONNECTED:
      ESP_LOGW(TAG, "Disconnected, reconnecting...");
      WiFi.reconnect();
      break;
    case IP_EVENT_STA_GOT_IP:
      ESP_LOGI(TAG, "Got IP: %s", WiFi.localIP().toString().c_str());
      break;
  }
});

// Non-blocking connection
WiFi.begin(ssid, password);
// Don't block with while(!WiFi.isConnected())
```

### Memory with WiFi

```cpp
// WiFi memory cost depends on the SoC, protocol stack, config, buffers, and
// runtime state. Measure the active build and preserve its required headroom.
size_t free_heap = esp_get_free_heap_size();
ESP_LOGI(TAG, "Free heap: %u bytes", static_cast<unsigned>(free_heap));
```

---

## Logging Best Practices

### ESP-IDF Logging

```cpp
#include "esp_log.h"

static const char* TAG = "my_component";

ESP_LOGE(TAG, "Error: %s", error_msg);     // Error
ESP_LOGW(TAG, "Warning: value=%d", val);   // Warning
ESP_LOGI(TAG, "Info: started");            // Info
ESP_LOGD(TAG, "Debug: state=%d", state);   // Debug
ESP_LOGV(TAG, "Verbose: raw=%02x", byte);  // Verbose

// Conditional compilation based on log level
#if CONFIG_LOG_DEFAULT_LEVEL >= ESP_LOG_DEBUG
  dump_buffer(data, len);
#endif
```

### ESPHome Logging

```cpp
ESP_LOGE("tag", "Error message");
ESP_LOGW("tag", "Warning message");
ESP_LOGI("tag", "Info message");
ESP_LOGD("tag", "Debug message");
ESP_LOGV("tag", "Verbose message");
ESP_LOGVV("tag", "Very verbose message");
```

---

## Timing and Delays

### Non-Blocking Patterns

```cpp
// BAD: Blocking delay
void loop() {
  do_work();
  delay(1000);  // Blocks everything!
}

// GOOD: Non-blocking with millis()
uint32_t last_run = 0;
const uint32_t INTERVAL = 1000;

void loop() {
  uint32_t now = millis();
  if (now - last_run >= INTERVAL) {
    last_run = now;
    do_work();
  }
  // Other tasks can run
}
```

### Microsecond Timing

```cpp
// Use esp_timer for accurate timing
#include "esp_timer.h"

int64_t start = esp_timer_get_time();  // Microseconds
// ... operation ...
int64_t elapsed_us = esp_timer_get_time() - start;
```

### Safe Delays (framework-specific APIs)

```cpp
// Short delays (doesn't yield to RTOS)
delayMicroseconds(100);
ets_delay_us(100);

// Longer delays (yields to RTOS)
delay(10);
vTaskDelay(pdMS_TO_TICKS(10));
```

---

## Persistent Storage (use the project's established backend)

Storage APIs and guarantees vary by framework. Do not switch a project to
ESPHome Preferences or raw NVS because of this example; follow its existing
persistence contract, recovery behavior, and write-frequency requirements.

### ESPHome Preferences (only for ESPHome components)

For an ESPHome component, its preference system may be appropriate and has
framework-specific caching and write behavior; confirm those semantics for the
installed ESPHome version.

**Docs:** [developers.esphome.io/blog/2026/02/12/entity-preferences](https://developers.esphome.io/blog/2026/02/12/entity-preferences-use-make_entity_preference-instead-of-get_preference_hash/)

```cpp
#include "esphome/core/preferences.h"
#include "esphome/core/helpers.h"  // for fnv1_hash

// Type constraint: T must be trivially copyable (POD structs, scalars — no std::string, no pointers)
struct MyConfig {
  uint32_t address{0};
  uint8_t channel{0};
  char name[24]{};
  bool is_valid() const { return address != 0; }
};

// ─── For EntityBase subclasses (Cover, Light, Switch, etc.) ───
// Hash is auto-derived from entity's object_id.
this->pref_ = this->make_entity_preference<MyConfig>(VERSION);

// ─── For non-entity classes (dynamic slots, managers) ───
// Compute a deterministic hash from a readable string + slot index.
uint32_t hash = fnv1_hash("my_component_slot") + slot_index;
auto pref = global_preferences->make_preference<MyConfig>(hash);

// Save and load:
MyConfig cfg{};
pref.save(&cfg);         // returns bool
pref.load(&cfg);         // returns bool (false if no data stored)

// To "delete" a preference, save an invalid/empty value:
MyConfig empty{};
pref.save(&empty);       // load() will succeed but is_valid() returns false
```

**Key rules:**
- `global_preferences` is available after `setup_priority::HARDWARE`
- Hashes must be unique across all preferences in the firmware
- Use `fnv1_hash("descriptive_string") + index` for stable, readable hashes
- The `version` parameter in `make_entity_preference<T>(version)` is XOR'd into the hash — bumping it silently invalidates old data
- Writes are cached in RAM and flushed periodically in this framework; still consider flash endurance, power-loss semantics, and the project's persistence requirements

### ESP-IDF NVS (only when the project uses direct NVS)

An ESP-IDF application that already uses direct NVS may use its documented API for an appropriate object. This is not an alternative to select automatically for an ESPHome or Arduino project.

The sequence below is illustrative and omits error handling. Check every API
result and follow the application's established atomicity, versioning, integrity,
readback, and recovery contract where one exists; a successful single-key write
does not by itself satisfy a multi-step persistence contract.

```cpp
#include "nvs_flash.h"
#include "nvs.h"

nvs_handle_t handle;
nvs_open("storage", NVS_READWRITE, &handle);
nvs_set_i32(handle, "counter", 42);
nvs_commit(handle);
nvs_close(handle);
```

### Write frequency

Avoid unnecessary flash writes, batch related changes where the contract permits,
and account for the storage layer's erase/write granularity and recovery behavior.

### Wear-leveling example (ESP-IDF NVS)

```cpp
// Avoid frequent writes to same key
// BAD: Write every loop
nvs_set_i32(handle, "counter", counter++);

// GOOD: Write periodically or on change
if (counter - last_saved > 100) {
  nvs_set_i32(handle, "counter", counter);
  last_saved = counter;
}
```

---

## ESPHome Component Guidelines

### Component Lifecycle

```cpp
class MyComponent : public Component {
 public:
  // Called once at startup
  void setup() override {
    // Initialize hardware
  }

  // Called every loop iteration
  void loop() override {
    // Non-blocking operations only!
  }

  // Called during config dump
  void dump_config() override {
    ESP_LOGCONFIG(TAG, "MyComponent:");
    ESP_LOGCONFIG(TAG, "  Pin: %d", pin_);
  }

  // Priority (higher = earlier setup)
  float get_setup_priority() const override {
    return setup_priority::DATA;  // After hardware, before network
  }
};
```

### Setup Priorities

| Priority | Value | Use For |
|----------|-------|---------|
| `BUS` | 1000 | SPI, I2C buses |
| `IO` | 900 | GPIO expanders |
| `HARDWARE` | 800 | Sensors, displays |
| `DATA` | 600 | Data processing |
| `PROCESSOR` | 400 | After all hardware |
| `WIFI` | 250 | Network-dependent |
| `AFTER_WIFI` | 200 | Services requiring network |

---

## Common Pitfalls

### 1. Watchdog Timeout

```cpp
// BAD: Long blocking operation
while (waiting) {
  // Watchdog will reset!
}

// GOOD: Yield periodically
while (waiting) {
  yield();  // Or vTaskDelay(1)
  if (timeout_expired()) break;
}
```

### 2. Stack Overflow

```cpp
// BAD: Recursive with deep stack
void parse(Node* n) {
  if (n->child) parse(n->child);  // Can overflow
}

// GOOD: Iterative or tail-recursive
void parse(Node* n) {
  while (n) {
    process(n);
    n = n->child;
  }
}
```

### 3. Heap Fragmentation

```cpp
// BAD: Frequent small allocations
for (int i = 0; i < 1000; i++) {
  char* buf = (char*)malloc(10);
  // ...
  free(buf);
}

// GOOD: Reuse buffers
char buf[10];
for (int i = 0; i < 1000; i++) {
  // Use buf
}
```

### 4. Flash Cache Restrictions in ISR (conditional)

```cpp
// Unsafe when this interrupt can run while flash cache is unavailable:
void IRAM_ATTR isr() {
  Serial.println("ISR");  // May crash!
}

// Example: defer work. If cache-off execution is required, verify all reachable
// code and data follow the selected target's documented placement rules.
// This flag only illustrates event publication: volatile alone is not C++
// inter-context synchronization and a bool can coalesce events. Use the
// project's verified ISR-safe handoff and consumer for the actual runtime.
volatile bool flag = false;
void IRAM_ATTR isr() {
  flag = true;  // Just set flag
}
```

---

## Debugging Tips

1. **Monitor heap**: use the target/framework API (`ESP.getFreeHeap()` for Arduino-ESP32, `heap_caps_get_free_size()` for ESP-IDF)
2. **Monitor stack**: use the selected FreeRTOS/SDK API and confirm its units/meaning
3. **Use assertions**: `configASSERT()`, `ESP_ERROR_CHECK()`
4. **Core dumps**: Enable in menuconfig for crash analysis
5. **JTAG debugging**: For step-through debugging
