local colors = require("colors")

sbar.default({
  padding_left = 4,
  padding_right = 4,
  icon = {
    font = "Hack Nerd Font:Bold:14.0",
    color = colors.FG1,
    padding_left = 8,
    padding_right = 4,
  },
  label = {
    font = "SF Pro:Semibold:13.0",
    color = colors.FG1,
    padding_left = 2,
    padding_right = 8,
  },
  background = {
    height = 26,
    corner_radius = 8,
    color = colors.TRANSPARENT,
  },
  updates = "on",
})
