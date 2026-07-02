# Переработанный план разработки Beltometer

1. Концепция и требования
Основная идея
Мод добавляет устройство Beltometer — измеритель пропускной способности конвейерной ленты, отображающий данные на экране над устройством.

Функциональные требования
Измерение количества предметов, проходящих через ленту
Отображение пропускной способности в единицах: /сек, /мин, /час
Настройка ширины окна усреднения (окна выборки)
Выбор поведения скользящего среднего (алгоритм усреднения)
Визуальный индикатор над устройством (текст/спрайт)

Ассет дисплея и сущность
Взять/адаптировать ассет дисплея (можно основать на display-panel из базовой игры)
Создать прототип сущности:
Коллизия, размещение
Графика устройства
Настроить рецепт и предмет для крафта
Разместить устройство в игре

### Как это работает в игре
```
[Лента] → (circuit network) → [Beltometer] → читает сигналы → считает дельту → отображает
```

- Лента подключается проводом к Beltometer
- Каждый тик лента отдаёт сигнал: `{железная-руда: 8, медная-руда: 3}` и т.д.
- Beltometer смотрит **изменение сигнала между тиками** — это и есть пропускная способность
- Отдельно по каждому предмету **или** суммарно

---

## Пересмотренная структура мода

```
Beltometer/
├── info.json
├── data.lua
├── control.lua
├── settings.lua
├── locale/
│   ├── en/beltometer.cfg
│   └── ru/beltometer.cfg
├── graphics/
│   ├── entity/
│   │   ├── beltometer.png        # основной спрайт (дисплей)
│   │   └── beltometer-shadow.png
│   ├── icons/
│   │   └── beltometer.png
│   └── display/
│       └── screen-overlay.png    # графика экрана
├── prototypes/
│   ├── entity.lua
│   ├── item.lua
│   ├── recipe.lua
│   └── technology.lua
└── scripts/
    ├── beltometer.lua    # логика измерения
    ├── averaging.lua     # алгоритмы усреднения
    └── gui.lua           # интерфейс настроек
```

---

## Этапы разработки

### Этап 1: Скелет мода

**info.json**
```json
{
  "name": "Beltometer",
  "version": "0.1.0",
  "title": "Beltometer",
  "author": "...",
  "description": "Belt throughput meter",
  "factorio_version": "2.0",
  "dependencies": ["base"]
}
```

**Задачи:**
- Создать структуру папок
- Написать info.json
- Проверить загрузку в игре

---

### Этап 2: Прототип сущности

За основу берём прототип типа **`arithmetic-combinator`** или **`constant-combinator`** — они уже умеют подключаться к цепи и имеют нужную геометрию для провода.

**prototypes/entity.lua:**
```lua
data:extend({
  {
    type = "arithmetic-combinator",
    -- или можно взять lamp / display-panel как базу
    name = "beltometer",
    
    -- подключение к цепи (провод)
    circuit_wire_max_distance = 9,
    circuit_connections = {...},
    
    -- графика дисплея
    sprites = {
      -- ссылка на наш ассет дисплея
    },
    
    -- индикатор над устройством (rendering)
    -- текст будем рисовать через rendering API в control.lua
  }
})
```

**Ключевые решения на этом этапе:**
- Размер устройства (1×1 или 1×2?)
- Направления (4 стороны?)
- Точки подключения провода

---

### Этап 3: Логика чтения сигналов (ядро)

Это самая важная часть. Лента отдаёт **текущее количество предметов** на ней, а не количество прошедших. Значит нужно считать **дельту**.

**scripts/beltometer.lua:**

```lua
-- Структура данных для каждого Beltometer
-- global.beltometers[unit_number] = {
--   entity = LuaEntity,
--   
--   -- буфер истории сигналов для окна усреднения
--   history = {
--     [tick] = { ["iron-ore"] = 5, ["copper-ore"] = 3, ... }
--   },
--   
--   -- предыдущий снимок сигналов
--   prev_signals = { ["iron-ore"] = 8, ... },
--   
--   -- накопленные дельты за текущий интервал
--   accumulated = { ["iron-ore"] = 0, ... },
--   
--   -- настройки
--   settings = {
--     time_unit = "sec",     -- "sec" | "min" | "hour"
--     window_size = 60,      -- тиков
--     avg_mode = "SMA",      -- "SMA" | "EMA"
--     display_mode = "total" -- "total" | "per_item"
--   }
-- }
```

**Алгоритм в on_tick:**

```
1. Каждые N тиков для каждого Beltometer:
   a. Прочитать текущие сигналы из circuit network
   b. Посчитать дельту: current - prev для каждого типа предмета
   c. Записать дельту в history[tick]
   d. Удалить из history записи старше window_size тиков
   e. Применить алгоритм усреднения к истории
   f. Пересчитать в нужные единицы (/sec, /min, /hour)
   g. Обновить отображение
```

**Важный нюанс — чтение сигналов:**
```lua
-- Читаем сигналы из input цепи (от ленты)
local network = entity.get_circuit_network(defines.wire_connector_id.circuit_red)
if network then
  local signals = network.signals
  -- signals = { {signal={type="item", name="iron-ore"}, count=8}, ... }
end
```

---

### Этап 4: Алгоритмы усреднения

**scripts/averaging.lua:**

```lua
local Averaging = {}

-- Простое скользящее среднее (SMA)
-- Берём все дельты в окне, суммируем, делим на размер окна
function Averaging.SMA(history, window_size, item_name)
  local sum = 0
  local count = 0
  for tick, deltas in pairs(history) do
    sum = sum + (deltas[item_name] or 0)
    count = count + 1
  end
  return count > 0 and (sum / window_size) or 0
end

-- Экспоненциальное скользящее среднее (EMA)
-- Свежие данные имеют больший вес
-- alpha — коэффициент сглаживания (0.1 = плавно, 0.9 = резко)
function Averaging.EMA(history, window_size, item_name, alpha)
  alpha = alpha or (2 / (window_size + 1))
  local ema = nil
  -- проходим по истории в хронологическом порядке
  local sorted_ticks = {} -- отсортированные тики
  for tick in pairs(history) do
    sorted_ticks[#sorted_ticks+1] = tick
  end
  table.sort(sorted_ticks)
  
  for _, tick in ipairs(sorted_ticks) do
    local value = history[tick][item_name] or 0
    if ema == nil then
      ema = value
    else
      ema = alpha * value + (1 - alpha) * ema
    end
  end
  return ema or 0
end

return Averaging
```

---

### Этап 5: Пересчёт единиц

```lua
-- items/tick → нужные единицы
local TICKS_PER_SEC  = 60
local TICKS_PER_MIN  = 3600
local TICKS_PER_HOUR = 216000

local function convert_rate(items_per_tick, unit)
  if unit == "sec"  then return items_per_tick * TICKS_PER_SEC  end
  if unit == "min"  then return items_per_tick * TICKS_PER_MIN  end
  if unit == "hour" then return items_per_tick * TICKS_PER_HOUR end
end

local function format_rate(value, unit)
  local suffix = {sec="/s", min="/m", hour="/h"}
  return string.format("%.1f%s", value, suffix[unit])
end
```

---

### Этап 6: Отображение на дисплее

Два режима отображения:

**Суммарная пропускная способность (`total`):**
```
[ Beltometer      ]
[   147.3 /min    ]
```

**По каждому предмету (`per_item`):**
```
[ Beltometer      ]
[ 🔴 120.0 /min   ]
[ 🟡  27.3 /min   ]
```

**Реализация через `rendering.draw_text`:**
```lua
-- Рисуем текст над устройством
local text_id = rendering.draw_text{
  text = "147.3 /min",
  surface = entity.surface,
  target = entity,
  target_offset = {0, -1.5},  -- над устройством
  color = {r=0.2, g=1, b=0.2},
  scale = 0.8,
  font = "default-bold",
  alignment = "center",
  only_in_alt_mode = false
}
```

Для режима `per_item` — несколько строк текста, одна под другой с отступом, с иконкой предмета через `rendering.draw_sprite`.

---

### Этап 7: GUI настроек

Открывается кликом на устройство:

```
┌─────────────────────────────┐
│  ⚙ Beltometer Settings      │
├─────────────────────────────┤
│  Единица измерения:         │
│  [/сек] [/мин] [/час]       │
├─────────────────────────────┤
│  Окно усреднения:           │
│  [60 тиков ] (1 сек)        │
│   ████████░░░░░░  слайдер   │
├─────────────────────────────┤
│  Алгоритм усреднения:       │
│  [SMA ▼]                    │
│   alpha EMA: [0.3]          │
├─────────────────────────────┤
│  Режим отображения:         │
│  [Суммарно] [По предметам]  │
└─────────────────────────────┘
```

**scripts/gui.lua** — обработка событий:
- `on_gui_opened` → открыть окно
- `on_gui_closed` → закрыть окно
- `on_gui_click` → переключение кнопок
- `on_gui_value_changed` → слайдер окна
- `on_gui_selection_state_changed` → дропдаун алгоритма
- `on_gui_text_changed` → поле alpha

---

### Этап 8: Оптимизация on_tick

Не обрабатывать все устройства каждый тик — распределить нагрузку:

```lua
script.on_event(defines.events.on_tick, function(event)
  local tick = event.tick
  
  -- Обрабатываем только часть устройств за тик
  -- Например при 100 устройствах — по 5 за тик
  local all_beltometers = global.beltometers
  local ids = global.beltometer_ids  -- массив unit_number
  
  local batch_size = 5
  local offset = tick % math.ceil(#ids / batch_size)
  
  for i = offset, #ids, batch_size do
    local id = ids[i]
    if all_beltometers[id] then
      update_beltometer(all_beltometers[id], tick)
    end
  end
end)
```

---

## Дорожная карта версий

| Версия | Содержание |
|--------|------------|
| **0.1.0** | Сущность + чтение сигналов + вывод суммарно /сек |
| **0.2.0** | Режим per_item + единицы /мин /час |
| **0.3.0** | GUI настроек + SMA/EMA + слайдер окна |
| **0.4.0** | Полировка графики дисплея + локализация RU/EN |
| **1.0.0** | Оптимизация + публикация на mod portal |
