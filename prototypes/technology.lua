data:extend({
  {
    type = "technology",
    name = "beltometer",
    icon = "__base__/graphics/icons/constant-combinator.png",
    icon_size = 64,
    prerequisites = {"circuit-network"},
    effects = {
      {
        type = "unlock-recipe",
        recipe = "beltometer",
      },
    },
    unit = {
      count = 50,
      ingredients = {
        {"automation-science-pack", 1},
      },
      time = 15,
    },
    order = "d-a-e",
  },
})
