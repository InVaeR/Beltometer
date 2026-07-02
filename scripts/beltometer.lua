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
  local data = {
    entity = entity,
    prev_signals = {},
    history = {},
    render_ids = {},
    settings = {
      time_unit = "sec",
      window_size = 60,
      avg_mode = "SMA",
      display_mode = "total",
      ema_alpha = 0.3,
    },
  }
  global.beltometers[entity.unit_number] = data
  global.beltometer_ids[#global.beltometer_ids + 1] = entity.unit_number
end

function beltometer.destroy(entity)
  local data = global.beltometers[entity.unit_number]
  if data then
    beltometer.clear_display(data)
    global.beltometers[entity.unit_number] = nil
  end
end

function beltometer.clear_display(data)
  for _, id in ipairs(data.render_ids) do
    if rendering.is_valid(id) then
      rendering.destroy(id)
    end
  end
  data.render_ids = {}
end

function beltometer.update(data, tick)
  local entity = data.entity
  local settings = data.settings

  if not entity.valid then
    beltometer.destroy(entity)
    return
  end

  local network = entity.get_circuit_network(defines.wire_connector_id.circuit_red)
  if not network then
    beltometer.clear_display(data)
    return
  end

  local signals = network.signals
  if not signals or #signals == 0 then
    beltometer.clear_display(data)
    return
  end

  local current = {}
  for _, signal in ipairs(signals) do
    if signal.signal.type == "item" then
      current[signal.signal.name] = signal.count
    end
  end

  local deltas = {}
  for name, count in pairs(current) do
    local prev = data.prev_signals[name] or 0
    local delta = count - prev
    if delta > 0 then
      deltas[name] = delta
    end
  end

  data.history[tick] = deltas

  local cutoff = tick - settings.window_size
  for t in pairs(data.history) do
    if t < cutoff then
      data.history[t] = nil
    end
  end

  data.prev_signals = current

  local all_items = {}
  for _, deltas in pairs(data.history) do
    for name in pairs(deltas) do
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
      rates[name] = averaging.SMA(data.history, settings.window_size, name)
    end
  else
    for name in pairs(all_items) do
      rates[name] = averaging.EMA(data.history, settings.window_size, name, settings.ema_alpha)
    end
  end

  local converted = {}
  for name, rate in pairs(rates) do
    converted[name] = convert_rate(rate, settings.time_unit)
  end

  beltometer.update_display(data, converted)
end

function beltometer.update_display(data, rates)
  beltometer.clear_display(data)

  local entity = data.entity
  local surface = entity.surface
  local settings = data.settings
  local render_ids = {}
  local color = {r = 0.2, g = 1, b = 0.2}

  if settings.display_mode == "total" then
    local total = 0
    for _, rate in pairs(rates) do
      total = total + rate
    end
    local text = format_rate(total, settings.time_unit)
    local id = rendering.draw_text({
      text = text,
      surface = surface,
      target = entity,
      target_offset = {0, -1.5},
      color = color,
      scale = 0.8,
      font = "default-bold",
      alignment = "center",
      only_in_alt_mode = false,
    })
    render_ids[#render_ids + 1] = id
  else
    local y_offset = -1.5
    for name, rate in pairs(rates) do
      local text = format_rate(rate, settings.time_unit)
      local id = rendering.draw_text({
        text = text,
        surface = surface,
        target = entity,
        target_offset = {0, y_offset},
        color = color,
        scale = 0.7,
        font = "default-bold",
        alignment = "center",
        only_in_alt_mode = false,
      })
      render_ids[#render_ids + 1] = id
      y_offset = y_offset - 0.35
    end
  end

  data.render_ids = render_ids
end

return beltometer
