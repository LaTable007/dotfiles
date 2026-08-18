local colors = require("colors")

sbar.default({
  -- Marges volontairement serrées : entre deux items voisins, l'écart total
  -- vaut label.padding_right + padding_right + padding_left + icon.padding_left.
  padding_left = 2,
  padding_right = 2,
  icon = {
    font = "Hack Nerd Font:Bold:14.0",
    color = colors.FG1,
    padding_left = 5,
    padding_right = 3,
  },
  label = {
    font = "SF Pro:Semibold:13.0",
    color = colors.FG1,
    padding_left = 2,
    padding_right = 5,
  },
  background = {
    height = 26,
    corner_radius = 8,
    color = colors.TRANSPARENT,
  },
  updates = "on",
})
