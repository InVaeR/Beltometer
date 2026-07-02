local averaging = require("scripts.averaging")

local TICKS_PER_SEC = 60
local TICKS_PER_MIN = 3600
local TICKS_PER_HOUR = 216000

local beltometer = {}

local function convert_rate(items_per_tick, unit)
  if unit == "sec" then return items_per_tick * TICKS_PER_SEC end
  if unit == "min" then return items_per_tick * TICKS_PER_MIN end
  if unit == "hour" then return items_per_tick * TICKS_PER_HOUR end
  return items_per_tick
end

local function format_rate(value, unit)
  local suffix = {sec = "/s", min = "/m", hour = "/h"}
  return string.format("%.1f%s", value, suffix[unit])
end

function beltometer.create(entity)
  local window_size = 60
  if settings and settings.global and settings.global["beltometer-default-window-size"] then
    window_size = settings.global["beltometer-default-window-size"].value
  end

  local unit_number = entity.unit_number
  local data = {
    entity = entity,
    unit_number = unit_number,
    history = {},
    render_objects = {},
    settings = {
      time_unit = "sec",
      window_size = window_size,
      avg_mode = "SMA",
      display_mode = "total",
      ema_alpha = 0.3,
    },
  }
  storage.beltometers[unit_number] = data
  storage.beltometer_ids[#storage.beltometer_ids + 1] = unit_number
end

function beltometer.destroy(unit_number)
  local data = storage.beltometers[unit_number]
  if data then
    beltometer.clear_display(data)
    storage.beltometers[unit_number] = nil
  end
end

function beltometer.clear_display(data)
  for _, obj in ipairs(data.render_objects) do
    if obj.valid then
      obj.destroy()
    end
  end
  data.render_objects = {}
end

local function read_wire_signals(entity, wire_id)
  local network = entity.get_circuit_network(wire_id)
  if not network then return {} end
  local signals = network.signals
  if not signals then return {} end

  local result = {}
  for _, signal in ipairs(signals) do
    if signal.signal then
      local stype = signal.signal.type
      local sname = signal.signal.name
      if (stype == nil or stype == "item") and prototypes.item[sname] then
        result[sname] = (result[sname] or 0) + signal.count
      end
    end
  end
  return result
end

local function merge_signals(a, b)
  if not next(a) then return b end
  if not next(b) then return a end
  local merged = {}
  for name, count in pairs(a) do merged[name] = count end
  for name, count in pairs(b) do merged[name] = (merged[name] or 0) + count end
  return merged
end

--- Lightweight: read pulse signals from both wires and store in history.
--- Runs every tick for every beltometer.
function beltometer.collect(data, tick)
  local entity = data.entity
  if not entity.valid then return end

  local red = read_wire_signals(entity, defines.wire_connector_id.circuit_red)
  local green = read_wire_signals(entity, defines.wire_connector_id.circuit_green)

  data.history[tick] = merge_signals(red, green)

  local cutoff = tick - data.settings.window_size
  for t in pairs(data.history) do
    if t <= cutoff then
      data.history[t] = nil
    end
  end
end

--- Expensive: calculate throughput and update rendering.
--- Runs batched (not every tick for every beltometer).
function beltometer.update_display(data)
  local settings = data.settings
  local window_size = settings.window_size

  local all_items = {}
  for _, signals in pairs(data.history) do
    for name in pairs(signals) do
      all_items[name] = true
    end
  end

  if not next(all_items) then
    beltometer.clear_display(data)
    return
  end

  local rates = {}
  if settings.avg_mode == "SMA" then
    for name in pairs(all_items) do
      rates[name] = averaging.SMA(data.history, window_size, name)
    end
  else
    for name in pairs(all_items) do
      rates[name] = averaging.EMA(data.history, window_size, name, settings.ema_alpha)
    end
  end

  local converted = {}
  for name, rate in pairs(rates) do
    converted[name] = convert_rate(rate, settings.time_unit)
  end

  beltometer.render_display(data, converted)
end

function beltometer.render_display(data, rates)
  beltometer.clear_display(data)

  local entity = data.entity
  local surface = entity.surface
  local settings = data.settings
  local render_objects = {}

  if settings.display_mode == "total" then
    local total = 0
    for _, rate in pairs(rates) do
      total = total + rate
    end
    if total == 0 then return end

    local obj = rendering.draw_text({
      text = format_rate(total, settings.time_unit),
      surface = surface,
      target = entity,
      target_offset = {0, -1.5},
      color = {r = 0.2, g = 1, b = 0.2},
      scale = 0.8,
      font = "default-bold",
      alignment = "center",
      only_in_alt_mode = false,
    })
    render_objects[#render_objects + 1] = obj
  else
    local y_offset = -1.5
    for name, rate in pairs(rates) do
      local obj = rendering.draw_text({
        text = format_rate(rate, settings.time_unit),
        surface = surface,
        target = entity,
        target_offset = {0, y_offset},
        color = {r = 0.2, g = 1, b = 0.2},
        scale = 0.7,
        font = "default-bold",
        alignment = "center",
        only_in_alt_mode = false,
      })
      render_objects[#render_objects + 1] = obj
      y_offset = y_offset - 0.35
    end
  end

  data.render_objects = render_objects
end

return beltometer
