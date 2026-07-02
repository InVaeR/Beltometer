local beltometer = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])

beltometer.name = "beltometer"
beltometer.minable = {mining_time = 0.2, result = "beltometer"}
beltometer.icon = "__base__/graphics/icons/constant-combinator.png"
beltometer.icon_size = 64

if beltometer.sprites and beltometer.sprites.sheets then
  for _, sheet in ipairs(beltometer.sprites.sheets) do
    sheet.tint = {r = 0.7, g = 0.85, b = 1.0}
    if sheet.hr_version then
      sheet.hr_version.tint = {r = 0.7, g = 0.85, b = 1.0}
    end
  end
end

data:extend({beltometer})
