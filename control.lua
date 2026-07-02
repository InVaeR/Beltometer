local beltometer = require("scripts.beltometer")
local gui = require("scripts.gui")

script.on_init(function()
  storage.beltometers = {}
  storage.beltometer_ids = {}
end)

script.on_load(function() end)

script.on_configuration_changed(function()
  if not storage.beltometers then storage.beltometers = {} end
  if not storage.beltometer_ids then storage.beltometer_ids = {} end
end)

local BATCH_SIZE = 5

script.on_event(defines.events.on_tick, function(event)
  local tick = event.tick
  local ids = storage.beltometer_ids
  local n = #ids
  if n == 0 then return end

  -- Collect data every tick + swap-remove invalid entities
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

  if n == 0 then return end

  -- Display update batched (dense array, # is correct)
  local offset = tick % math.ceil(n / BATCH_SIZE)
  for j = offset + 1, n, BATCH_SIZE do
    local data = storage.beltometers[ids[j]]
    if data and data.entity.valid then
      beltometer.update_display(data)
    end
  end
end)

local function on_built(event)
  local entity = event.entity
  if entity and entity.name == "beltometer" then
    beltometer.create(entity)
  end
end

local function on_mined(event)
  local entity = event.entity
  if entity and entity.name == "beltometer" then
    beltometer.destroy(entity.unit_number)
  end
end

script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.on_player_mined_entity, on_mined)
script.on_event(defines.events.on_robot_mined_entity, on_mined)
script.on_event(defines.events.on_entity_died, on_mined)

script.on_event(defines.events.on_gui_opened, gui.on_opened)
script.on_event(defines.events.on_gui_closed, gui.on_closed)
script.on_event(defines.events.on_gui_value_changed, gui.on_value_changed)
script.on_event(defines.events.on_gui_selection_state_changed, gui.on_selection_changed)
script.on_event(defines.events.on_gui_text_changed, gui.on_text_changed)
