local colors = require("colors")

local battery = sbar.add("item", "battery", {
  position = "right",
  update_freq = 120,
})

local function refresh()
  sbar.exec("pmset -g batt", function(batt_info)
    local percentage = batt_info:match("(%d+)%%")
    local charging = batt_info:match("AC Power") ~= nil
    if not percentage then
      return
    end

    local percent_num = tonumber(percentage)
    local icon
    local colour

    if charging then
      icon = "󰂄"
      colour = colors.GREEN
    elseif percent_num < 20 then
      icon = ""
      colour = colors.RED
    else
      colour = colors.YELLOW -- same base color as the volume glyph
      if percent_num >= 80 then
        icon = ""
      elseif percent_num >= 50 then
        icon = ""
      else
        icon = ""
      end
    end

    battery:set({
      icon = { string = icon, color = colour },
      label = { string = percentage .. "%", color = colour },
    })
  end)
end

battery:subscribe({ "routine", "system_woke", "power_source_change" }, refresh)
refresh()
