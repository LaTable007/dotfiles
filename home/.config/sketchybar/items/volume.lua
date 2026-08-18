local colors = require("colors")

-- Glyph only, no percentage: the icon shape itself marks the intensity tier.
local volume = sbar.add("item", "volume", {
  position = "right",
  icon = { color = colors.YELLOW },
  label = { drawing = "off" },
})

local function refresh(vol)
  local icon = "󰕾" -- high
  if vol == 0 then
    icon = "󰖁" -- muted
  elseif vol < 34 then
    icon = "󰕿" -- low
  elseif vol < 67 then
    icon = "󰖀" -- medium
  end

  volume:set({ icon = { string = icon } })
end

volume:subscribe("volume_change", function(env)
  refresh(tonumber(env.INFO) or 0)
end)

-- Populate the initial value on startup (volume_change only fires on actual changes)
sbar.exec("osascript -e 'output volume of (get volume settings)'", function(vol)
  refresh(tonumber(vol) or 0)
end)
