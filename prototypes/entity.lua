local function make_circuit_connection_sprites()
  return {
    red = {
      filename = "__base__/graphics/entity/circuit-connector/hr-connector-idle-8.6.png",
      width = 54, height = 54,
      scale = 0.5,
      shift = {0.21875, -0.09375},
    },
    green = {
      filename = "__base__/graphics/entity/circuit-connector/hr-connector-idle-8.6.png",
      width = 54, height = 54,
      scale = 0.5,
      shift = {0.21875, -0.09375},
    },
  }
end

local function make_combinator_sprites()
  local tint = {r=0.7, g=0.85, b=1}
  return {
    north = {
      layers = {
        {
          filename = "__base__/graphics/entity/constant-combinator/constant-combinator.png",
          width = 44, height = 36,
          frame_count = 1,
          shift = {0.109375, 0.0625},
          tint = tint,
        },
        {
          filename = "__base__/graphics/entity/constant-combinator/constant-combinator-shadow.png",
          width = 54, height = 36,
          frame_count = 1,
          shift = {0.484375, 0.1875},
          draw_as_shadow = true,
        },
      },
    },
    east = {
      layers = {
        {
          filename = "__base__/graphics/entity/constant-combinator/constant-combinator.png",
          x = 44,
          width = 44, height = 36,
          frame_count = 1,
          shift = {0.109375, 0.0625},
          tint = tint,
        },
        {
          filename = "__base__/graphics/entity/constant-combinator/constant-combinator-shadow.png",
          x = 54,
          width = 54, height = 36,
          frame_count = 1,
          shift = {0.484375, 0.1875},
          draw_as_shadow = true,
        },
      },
    },
    south = {
      layers = {
        {
          filename = "__base__/graphics/entity/constant-combinator/constant-combinator.png",
          x = 88,
          width = 44, height = 36,
          frame_count = 1,
          shift = {0.109375, 0.0625},
          tint = tint,
        },
        {
          filename = "__base__/graphics/entity/constant-combinator/constant-combinator-shadow.png",
          x = 108,
          width = 54, height = 36,
          frame_count = 1,
          shift = {0.484375, 0.1875},
          draw_as_shadow = true,
        },
      },
    },
    west = {
      layers = {
        {
          filename = "__base__/graphics/entity/constant-combinator/constant-combinator.png",
          x = 132,
          width = 44, height = 36,
          frame_count = 1,
          shift = {0.109375, 0.0625},
          tint = tint,
        },
        {
          filename = "__base__/graphics/entity/constant-combinator/constant-combinator-shadow.png",
          x = 162,
          width = 54, height = 36,
          frame_count = 1,
          shift = {0.484375, 0.1875},
          draw_as_shadow = true,
        },
      },
    },
  }
end

local function make_led_sprites()
  return {
    north = {
      filename = "__base__/graphics/entity/constant-combinator/constant-combinator-activity-led.png",
      width = 38, height = 42,
      frame_count = 1,
      shift = {0.109375, -0.1875},
    },
    east = {
      filename = "__base__/graphics/entity/constant-combinator/constant-combinator-activity-led.png",
      x = 38,
      width = 38, height = 42,
      frame_count = 1,
      shift = {0.109375, -0.1875},
    },
    south = {
      filename = "__base__/graphics/entity/constant-combinator/constant-combinator-activity-led.png",
      x = 76,
      width = 38, height = 42,
      frame_count = 1,
      shift = {0.109375, -0.1875},
    },
    west = {
      filename = "__base__/graphics/entity/constant-combinator/constant-combinator-activity-led.png",
      x = 114,
      width = 38, height = 42,
      frame_count = 1,
      shift = {0.109375, -0.1875},
    },
  }
end

data:extend({
  {
    type = "constant-combinator",
    name = "beltometer",
    icon = "__base__/graphics/icons/constant-combinator.png",
    icon_size = 64,
    flags = {"placeable-player", "player-creation"},
    minable = {mining_time = 0.2, result = "beltometer"},
    max_health = 150,
    corpse = "small-remnants",
    collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
    selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
    circuit_wire_max_distance = 9,
    circuit_connection_sprites = make_circuit_connection_sprites(),
    sprites = make_combinator_sprites(),
    activity_led_sprites = make_led_sprites(),
    activity_led_light_offsets = {
      {0, 0}, {0, 0}, {0, 0}, {0, 0}
    },
    activity_led_light = {
      intensity = 0.8,
      size = 1,
      color = {r=0.3, g=1, b=0.3},
    },
    draw_circuit_wires = true,
    draw_copper_wires = true,
  },
})
