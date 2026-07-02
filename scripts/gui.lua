local gui = {}

local function get_player(event)
  if event.player_index then
    return game.get_player(event.player_index)
  end
  return nil
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

  local tbl = frame.add{type = "table", column_count = 2}

  tbl.add{type = "label", caption = {"gui.beltometer-time-unit"}}
  local time_unit_dropdown = tbl.add{
    type = "drop-down",
    name = "beltometer-time-unit",
    items = {{"gui.beltometer-unit-sec"}, {"gui.beltometer-unit-min"}, {"gui.beltometer-unit-hour"}},
    selected_index = data.settings.time_unit == "sec" and 1
      or data.settings.time_unit == "min" and 2
      or 3,
  }

  tbl.add{type = "label", caption = {"gui.beltometer-window-size"}}
  local window_slider = tbl.add{
    type = "slider",
    name = "beltometer-window-size",
    minimum_value = 1,
    maximum_value = 600,
    value = data.settings.window_size,
    discrete_slider = true,
  }
  local window_label = frame.add{
    type = "label",
    name = "beltometer-window-label",
    caption = {"gui.beltometer-window-label", data.settings.window_size, string.format("%.1f", data.settings.window_size / 60)},
  }

  tbl.add{type = "label", caption = {"gui.beltometer-avg-mode"}}
  local avg_dropdown = tbl.add{
    type = "drop-down",
    name = "beltometer-avg-mode",
    items = {{"gui.beltometer-avg-sma"}, {"gui.beltometer-avg-ema"}},
    selected_index = data.settings.avg_mode == "SMA" and 1 or 2,
  }

  tbl.add{type = "label", caption = {"gui.beltometer-ema-alpha"}}
  local alpha_field = tbl.add{
    type = "textfield",
    name = "beltometer-ema-alpha",
    text = tostring(data.settings.ema_alpha),
    numeric = true,
    allow_decimal = true,
    allow_negative = false,
  }

  tbl.add{type = "label", caption = {"gui.beltometer-display-mode"}}
  local display_dropdown = tbl.add{
    type = "drop-down",
    name = "beltometer-display-mode",
    items = {{"gui.beltometer-display-total"}, {"gui.beltometer-display-per-item"}},
    selected_index = data.settings.display_mode == "total" and 1 or 2,
  }

  frame.entity = entity
  frame.unit_number = entity.unit_number
  frame.force_auto_center()
end

function gui.on_opened(event)
  local entity = event.entity
  if not entity or entity.name ~= "beltometer" then return end

  local player = get_player(event)
  if not player then return end

  local data = global.beltometers[entity.unit_number]
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

function gui.on_click(event)
  local element = event.element
  if not element then return end

  local frame = element
  while frame and frame.name ~= "beltometer_frame" do
    frame = frame.parent
  end
  if not frame or not frame.unit_number then return end

  local data = global.beltometers[frame.unit_number]
  if not data then return end

  if element.name == "beltometer-time-unit" then
    local items = {"sec", "min", "hour"}
    data.settings.time_unit = items[element.selected_index]
  elseif element.name == "beltometer-avg-mode" then
    local items = {"SMA", "EMA"}
    data.settings.avg_mode = items[element.selected_index]
  elseif element.name == "beltometer-display-mode" then
    local items = {"total", "per_item"}
    data.settings.display_mode = items[element.selected_index]
  end
end

function gui.on_value_changed(event)
  local element = event.element
  if not element then return end

  local frame = element.parent
  while frame and frame.name ~= "beltometer_frame" do
    frame = frame.parent
  end
  if not frame or not frame.unit_number then return end

  local data = global.beltometers[frame.unit_number]
  if not data then return end

  if element.name == "beltometer-window-size" then
    data.settings.window_size = element.slider_value
    local label = frame["beltometer-window-label"]
    if label then
      label.caption = {"gui.beltometer-window-label", element.slider_value, string.format("%.1f", element.slider_value / 60)}
    end
  end
end

function gui.on_selection_changed(event)
  local element = event.element
  if not element then return end

  local frame = element.parent
  while frame and frame.name ~= "beltometer_frame" do
    frame = frame.parent
  end
  if not frame or not frame.unit_number then return end

  local data = global.beltometers[frame.unit_number]
  if not data then return end

  if element.name == "beltometer-time-unit" then
    local items = {"sec", "min", "hour"}
    data.settings.time_unit = items[element.selected_index]
  elseif element.name == "beltometer-avg-mode" then
    local items = {"SMA", "EMA"}
    data.settings.avg_mode = items[element.selected_index]
  elseif element.name == "beltometer-display-mode" then
    local items = {"total", "per_item"}
    data.settings.display_mode = items[element.selected_index]
  end
end

function gui.on_text_changed(event)
  local element = event.element
  if not element then return end

  local frame = element.parent
  while frame and frame.name ~= "beltometer_frame" do
    frame = frame.parent
  end
  if not frame or not frame.unit_number then return end

  local data = global.beltometers[frame.unit_number]
  if not data then return end

  if element.name == "beltometer-ema-alpha" then
    local val = tonumber(element.text)
    if val and val > 0 and val <= 1 then
      data.settings.ema_alpha = val
    end
  end
end

return gui
