local beltometer = require("scripts.beltometer")
local gui = require("scripts.gui")

script.on_init(function()
  global.beltometers = {}
  global.beltometer_ids = {}
end)

script.on_load(function() end)

local BATCH_SIZE = 5

script.on_event(defines.events.on_tick, function(event)
  local ids = global.beltometer_ids
  if not ids or #ids == 0 then return end

  local tick = event.tick
  local offset = (tick % math.ceil(#ids / BATCH_SIZE))

  for i = offset + 1, #ids, BATCH_SIZE do
    local id = ids[i]
    if id then
      local data = global.beltometers[id]
      if data then
        if data.entity.valid then
          beltometer.update(data, tick)
        else
          beltometer.destroy(data.entity)
          ids[i] = nil
        end
      end
    end
  end

  if tick % 600 == 0 then
    local cleaned = {}
    for _, id in ipairs(ids) do
      if id then
        cleaned[#cleaned + 1] = id
      end
    end
    global.beltometer_ids = cleaned
  end
end)

local function on_built(event)
  local entity = event.created_entity
  if entity and entity.name == "beltometer" then
    beltometer.create(entity)
  end
end

local function on_mined(event)
  local entity = event.entity
  if entity and entity.name == "beltometer" then
    beltometer.destroy(entity)
  end
end

script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_robot_built_entity, on_built)
script.on_event(defines.events.on_player_mined_entity, on_mined)
script.on_event(defines.events.on_robot_mined_entity, on_mined)
script.on_event(defines.events.on_entity_died, on_mined)

script.on_event(defines.events.on_gui_opened, gui.on_opened)
script.on_event(defines.events.on_gui_closed, gui.on_closed)
script.on_event(defines.events.on_gui_click, gui.on_click)
script.on_event(defines.events.on_gui_value_changed, gui.on_value_changed)
script.on_event(defines.events.on_gui_selection_state_changed, gui.on_selection_changed)
script.on_event(defines.events.on_gui_text_changed, gui.on_text_changed)
