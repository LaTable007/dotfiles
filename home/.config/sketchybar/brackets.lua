local colors = require("colors")

sbar.add("bracket", "rightItems", {
  "cpu",
  "ram",
  "temperature",
  "battery",
  "network",
  "network.up",
  "network.down",
  "audio_output",
  "volume",
  "datetime",
}, {
  background = {
    color = colors.PILL_BG,
    corner_radius = 10,
    height = 30,
  },
})
