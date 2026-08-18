local colors = require("colors")

-- Occupe le centre de la barre, laissé vide par les workspaces (gauche) et
-- les stats (droite). Porte son propre fond, donc pas de bracket : un bracket
-- dessinerait un second rectangle par-dessus celui-ci.
local front_app = sbar.add("item", "front_app", {
  position = "center",
  icon = { drawing = "off" },
  label = {
    font = "SF Pro:Bold:13.0",
    color = colors.FG0,
    padding_left = 10,
    padding_right = 10,
  },
  background = {
    color = colors.PILL_BG,
    corner_radius = 10,
    height = 30,
  },
})

-- env.INFO porte le nom de l'application, pas besoin d'interroger AeroSpace.
front_app:subscribe("front_app_switched", function(env)
  front_app:set({ label = { string = env.INFO } })
end)
