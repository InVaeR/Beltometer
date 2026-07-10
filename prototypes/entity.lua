local rtint = {r = 0.7, g = 0.85, b = 1.0}

local vanilla = data.raw["display-panel"]["display-panel"]
local entity = table.deepcopy(vanilla)

entity.name = "beltometer"
entity.minable = {mining_time = 0.2, result = "beltometer"}
entity.icons = {{icon = "__base__/graphics/icons/display-panel.png", tint = rtint}}
entity.icon = nil

local function tint_sprite(sprite)
  if not sprite then return end
  if sprite.layers then
    for _, layer in ipairs(sprite.layers) do
      if not layer.draw_as_shadow then
        layer.tint = rtint
      end
    end
  elseif sprite.sheet then
    if not sprite.sheet.draw_as_shadow then
      sprite.sheet.tint = rtint
    end
  elseif not sprite.draw_as_shadow then
    sprite.tint = rtint
  end
end

local sprites = entity.sprites
if sprites then
  if sprites.north or sprites.east or sprites.south or sprites.west then
    tint_sprite(sprites.north)
    tint_sprite(sprites.east)
    tint_sprite(sprites.south)
    tint_sprite(sprites.west)
  else
    tint_sprite(sprites)
  end
end

data:extend({entity})
