local beltometer = require("scripts.beltometer")

local gui = {}

local function get_player(event)
  if event.player_index then
    return game.get_player(event.player_index)
  end
  return nil
end

local function find_frame(element)
  while element do
    if element.name == "beltometer_frame" then
      return element
    end
    element = element.parent
  end
  return nil
end

local function update_display_for_frame(frame)
  if not frame.tags or not frame.tags.unit_number then return end
  local data = storage.beltometers[frame.tags.unit_number]
  if data and data.entity.valid then
    beltometer.update_display(data)
  end
end

local function build_settings_frame(player, entity, data)
  if player.gui.screen.beltometer_frame then
    player.gui.screen.beltometer_frame.destroy()
  end

  local frame = player.gui.screen.add{
    type = "frame",
    name = "beltometer_frame",
    caption = {"gui.beltometer-title"},
    direction = "vertical",
    auto_center = true,
  }
  frame.tags = {unit_number = entity.unit_number}

  local tbl = frame.add{type = "table", column_count = 2}

  tbl.add{type = "label", caption = {"gui.beltometer-time-unit"}}
  tbl.add{
    type = "drop-down",
    name = "beltometer-time-unit",
    items = {
      {"gui.beltometer-unit-sec"},
      {"gui.beltometer-unit-min"},
      {"gui.beltometer-unit-hour"},
    },
    selected_index = data.settings.time_unit == "sec" and 1
      or data.settings.time_unit == "min" and 2
      or 3,
  }

  tbl.add{type = "label", caption = {"gui.beltometer-window-size"}}
  tbl.add{
    type = "slider",
    name = "beltometer-window-size",
    minimum_value = 1,
    maximum_value = 600,
    value = data.settings.window_size,
    discrete_slider = true,
    value_step = 1,
  }
  frame.add{
    type = "label",
    name = "beltometer-window-label",
    caption = {
      "gui.beltometer-window-label",
      data.settings.window_size,
      string.format("%.1f", data.settings.window_size / 60),
    },
  }

  tbl.add{type = "label", caption = {"gui.beltometer-avg-mode"}}
  tbl.add{
    type = "drop-down",
    name = "beltometer-avg-mode",
    items = {
      {"gui.beltometer-avg-sma"},
      {"gui.beltometer-avg-ema"},
    },
    selected_index = data.settings.avg_mode == "SMA" and 1 or 2,
  }

  tbl.add{type = "label", caption = {"gui.beltometer-ema-alpha"}}
  tbl.add{
    type = "textfield",
    name = "beltometer-ema-alpha",
    text = tostring(data.settings.ema_alpha),
    numeric = true,
    allow_decimal = true,
    allow_negative = false,
  }

  tbl.add{type = "label", caption = {"gui.beltometer-display-mode"}}
  tbl.add{
    type = "drop-down",
    name = "beltometer-display-mode",
    items = {
      {"gui.beltometer-display-total"},
      {"gui.beltometer-display-per-item"},
    },
    selected_index = data.settings.display_mode == "total" and 1 or 2,
  }

  frame.force_auto_center()
end

function gui.on_opened(event)
  local entity = event.entity
  if not entity or entity.name ~= "beltometer" then return end

  local player = get_player(event)
  if not player then return end

  local data = storage.beltometers[entity.unit_number]
  if not data then return end

  build_settings_frame(player, entity, data)
end

function gui.on_closed(event)
  local element = event.element
  if not element then return end

  if element.name == "beltometer_frame" then
    element.destroy()
  end
end

function gui.on_value_changed(event)
  local element = event.element
  if not element then return end

  local frame = find_frame(element)
  if not frame or not frame.tags or not frame.tags.unit_number then return end

  local data = storage.beltometers[frame.tags.unit_number]
  if not data then return end

  if element.name == "beltometer-window-size" then
    data.settings.window_size = element.slider_value
    local label = frame["beltometer-window-label"]
    if label then
      label.caption = {
        "gui.beltometer-window-label",
        element.slider_value,
        string.format("%.1f", element.slider_value / 60),
      }
    end
    update_display_for_frame(frame)
  end
end

function gui.on_selection_changed(event)
  local element = event.element
  if not element then return end

  local frame = find_frame(element)
  if not frame or not frame.tags or not frame.tags.unit_number then return end

  local data = storage.beltometers[frame.tags.unit_number]
  if not data then return end

  if element.name == "beltometer-time-unit" then
    local items = {"sec", "min", "hour"}
    data.settings.time_unit = items[element.selected_index]
    update_display_for_frame(frame)
  elseif element.name == "beltometer-avg-mode" then
    local items = {"SMA", "EMA"}
    data.settings.avg_mode = items[element.selected_index]
    update_display_for_frame(frame)
  elseif element.name == "beltometer-display-mode" then
    local items = {"total", "per_item"}
    data.settings.display_mode = items[element.selected_index]
    update_display_for_frame(frame)
  end
end

function gui.on_text_changed(event)
  local element = event.element
  if not element then return end

  local frame = find_frame(element)
  if not frame or not frame.tags or not frame.tags.unit_number then return end

  local data = storage.beltometers[frame.tags.unit_number]
  if not data then return end

  if element.name == "beltometer-ema-alpha" then
    local val = tonumber(element.text)
    if val and val > 0 and val <= 1 then
      data.settings.ema_alpha = val
    end
  end
end

return gui
