local colors = require("colors")

-- y_offset pushes the bar down from the screen's top edge by GAP (10px),
-- matching the gap AeroSpace leaves everywhere else (see gaps.outer.top in
-- aerospace.toml = bar height 34 + y_offset 10 + GAP 10 = 54).
sbar.bar({
  position = "top",
  height = 34,
  y_offset = 10,
  color = colors.BAR_BG,
  padding_left = 8,
  padding_right = 8,
  corner_radius = 0,
})
