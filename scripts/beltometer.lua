local averaging = require("scripts.averaging")

local SAMPLE_TICKS = 60
local MAX_WINDOW = 60

local beltometer = {}

local PANEL_ALWAYS = {
  first_signal = {type = "virtual", name = "signal-everything"},
  comparator = "≥",
  constant = 0,
}

local MAX_LINES = 5

local function set_panel_messages(data, lines)
  local entity = data.entity
  if not entity.valid then return end
  local cb = entity.get_or_create_control_behavior()
  local count = math.min(#lines, MAX_LINES)
  local messages = {}

  for i = 1, count do
    local line = lines[i]
    messages[i] = {
      text = line.text,
      icon = line.icon,
      condition = PANEL_ALWAYS,
    }
  end

  cb.messages = messages
  entity.display_panel_always_show = true
  entity.display_panel_show_in_chart = false
end

local function convert_rate(items_per_sec, unit)
  if unit == "min" then return items_per_sec * 60 end
  if unit == "hour" then return items_per_sec * 3600 end
  return items_per_sec
end

local function format_rate(value, unit, partial)
  local suffix = {sec = "/s", min = "/m", hour = "/h"}
  local prefix = partial and "~" or ""
  return string.format("%s%.1f%s", prefix, value, suffix[unit])
end

function beltometer.create(entity)
  local window_size = 10
  if settings and settings.global and settings.global["beltometer-default-window-size"] then
    window_size = settings.global["beltometer-default-window-size"].value
  end

  local unit_number = entity.unit_number
  local data = {
    entity = entity,
    unit_number = unit_number,
    history = {},
    accumulator = {},
    phase = unit_number % SAMPLE_TICKS,
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
  if data.entity.valid then
    set_panel_messages(data, {})
  end
end

local function read_wire_signals(entity)
  local result = {}
  local function add_net(net)
    if not net or not net.signals then return end
    for _, sig in ipairs(net.signals) do
      local s = sig.signal
      if s and sig.count > 0 and (s.type == nil or s.type == "item") and prototypes.item[s.name] then
        result[s.name] = (result[s.name] or 0) + sig.count
      end
    end
  end

  add_net(entity.get_circuit_network(defines.wire_connector_id.circuit_red))
  add_net(entity.get_circuit_network(defines.wire_connector_id.circuit_green))
  return result
end

function beltometer.collect(data, tick)
  local entity = data.entity
  if not entity.valid then return end

  local signals = read_wire_signals(entity)
  local acc = data.accumulator
  for name, count in pairs(signals) do
    acc[name] = (acc[name] or 0) + count
  end

  if tick % SAMPLE_TICKS == data.phase then
    local history = data.history
    history[#history + 1] = acc
    data.accumulator = {}
    while #history > MAX_WINDOW do
      table.remove(history, 1)
    end
    beltometer.update_display(data)
  end
end

function beltometer.update_display(data)
  local settings = data.settings
  local window_size = settings.window_size
  local history = data.history
  local entity = data.entity
  if not entity.valid then return end

  if #history == 0 then
    set_panel_messages(data, {{text = "..."}})
    return
  end

  local partial = #history < window_size
  local n = #history
  local w = math.min(n, window_size)
  local all_items = {}
  for i = n - w + 1, n do
    for name in pairs(history[i]) do
      all_items[name] = true
    end
  end

  local rates = {}
  if settings.avg_mode == "SMA" then
    for name in pairs(all_items) do
      rates[name] = averaging.SMA(history, window_size, name)
    end
  else
    for name in pairs(all_items) do
      rates[name] = averaging.EMA(history, window_size, name, settings.ema_alpha)
    end
  end

  local converted = {}
  for name, rate in pairs(rates) do
    converted[name] = convert_rate(rate, settings.time_unit)
  end

  beltometer.render_display(data, converted, partial)
end

function beltometer.render_display(data, rates, partial)
  local entity = data.entity
  local settings = data.settings

  local names = {}
  for name, rate in pairs(rates) do
    if rate > 0 then
      names[#names + 1] = name
    end
  end
  table.sort(names)

  if #names == 0 then
    set_panel_messages(data, {})
    return
  end

  local total = 0
  local icons = {}
  for _, name in ipairs(names) do
    total = total + rates[name]
    icons[#icons + 1] = string.format("[item=%s]", name)
  end

  local lines = {
    {
      text = table.concat(icons) .. " " .. format_rate(total, settings.time_unit, partial),
      icon = {type = "item", name = names[1]},
    },
  }

  if settings.display_mode == "per_item" then
    for _, name in ipairs(names) do
      lines[#lines + 1] = {
        text = string.format("[item=%s]%s", name, format_rate(rates[name], settings.time_unit, partial)),
        icon = {type = "item", name = name},
      }
    end
  end

  set_panel_messages(data, lines)
end

return beltometer
