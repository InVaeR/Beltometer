local beltometer = require("scripts.beltometer")
local gui = require("scripts.gui")

script.on_init(function()
  storage.beltometers = {}
  storage.beltometer_ids = {}
end)

script.on_configuration_changed(function()
  storage.beltometers = storage.beltometers or {}
  storage.beltometer_ids = storage.beltometer_ids or {}
  for _, data in pairs(storage.beltometers) do
    if not data.phase then
      data.phase = data.unit_number % 60
      data.history = {}
      data.accumulator = {}
      local ws = data.settings.window_size or 10
      if ws > 60 then ws = math.floor(ws / 60) end
      data.settings.window_size = math.max(1, math.min(60, ws))
      for _, obj in pairs(data.render_objects or {}) do
        if obj.valid then obj.destroy() end
      end
      data.render_objects = {}
    end
  end
end)

script.on_event(defines.events.on_tick, function(event)
  local tick = event.tick
  local ids = storage.beltometer_ids
  local n = #ids
  if n == 0 then return end

  local i = 1
  while i <= n do
    local id = ids[i]
    local data = storage.beltometers[id]
    if data and data.entity.valid then
      beltometer.collect(data, tick)
      i = i + 1
    else
      beltometer.destroy(id)
      ids[i] = ids[n]
      ids[n] = nil
      n = n - 1
    end
  end
end)

local function on_built(event)
  local entity = event.entity
  if entity and entity.valid and entity.name == "beltometer" then
    beltometer.create(entity)
  end
end

local function on_mined(event)
  local entity = event.entity
  if entity and entity.valid and entity.name == "beltometer" then
    beltometer.destroy(entity.unit_number)
  end
end

local filter = {{filter = "name", name = "beltometer"}}
script.on_event(defines.events.on_built_entity, on_built, filter)
script.on_event(defines.events.on_robot_built_entity, on_built, filter)
script.on_event(defines.events.script_raised_built, on_built, filter)
script.on_event(defines.events.script_raised_revive, on_built, filter)
script.on_event(defines.events.on_player_mined_entity, on_mined, filter)
script.on_event(defines.events.on_robot_mined_entity, on_mined, filter)
script.on_event(defines.events.on_entity_died, on_mined, filter)
script.on_event(defines.events.script_raised_destroy, on_mined, filter)

script.on_event(defines.events.on_gui_opened, gui.on_opened)
script.on_event(defines.events.on_gui_closed, gui.on_closed)
script.on_event(defines.events.on_gui_value_changed, gui.on_value_changed)
script.on_event(defines.events.on_gui_selection_state_changed, gui.on_selection_changed)
script.on_event(defines.events.on_gui_text_changed, gui.on_text_changed)
