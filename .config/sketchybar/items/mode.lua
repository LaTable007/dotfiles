local colors = require("colors")

sbar.add("event", "aerospace_mode_change")

local mode = sbar.add("item", "aerospace_mode", {
  position = "left",
  icon = { drawing = "off" },
  label = {
    string = "MAIN",
    font = "Hack Nerd Font:Bold:11.0",
    color = colors.BG0,
    padding_left = 8,
    padding_right = 8,
  },
  background = {
    -- AQUA, not GREEN: matches the TEMP tag on the right so the bar carries a
    -- single green. RED still marks service mode.
    color = colors.AQUA,
    corner_radius = 8,
    height = 24,
  },
})

local function refresh()
  sbar.exec("aerospace list-modes --current", function(out)
    local current = out:gsub("%s+$", "")
    local is_service = current == "service"

    mode:set({
      label = { string = current:upper() },
      background = { color = is_service and colors.RED or colors.AQUA },
    })
  end)
end

mode:subscribe({ "aerospace_mode_change", "forced" }, refresh)
refresh()
