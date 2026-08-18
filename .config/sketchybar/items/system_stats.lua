local colors = require("colors")

-- Order of sbar.add() calls below matters: on position="right", the first
-- item added ends up closest to the screen edge, each next one shifts left.
-- temperature added first -> rightmost of this trio, cpu added last -> leftmost.
-- Text tags instead of icon glyphs: guaranteed to render and unambiguous,
-- unlike Nerd Font icon glyphs which can look similar to each other at a glance.
local tag_font = "SF Pro:Heavy:10.0"

local temperature = sbar.add("item", "temperature", {
  position = "right",
  update_freq = 5,
  icon = { string = "TEMP", font = tag_font, color = colors.AQUA },
  label = { color = colors.FG1 },
})

local ram = sbar.add("item", "ram", {
  position = "right",
  icon = { string = "RAM", font = tag_font, color = colors.BLUE },
  label = { color = colors.FG1 },
})

local cpu = sbar.add("item", "cpu", {
  position = "right",
  icon = { string = "CPU", font = tag_font, color = colors.PURPLE },
  label = { color = colors.FG1 },
})

local function level_color(value, warn, critical)
  if value >= critical then
    return colors.RED
  elseif value >= warn then
    return colors.ORANGE
  end
  return colors.FG1
end

-- Single macmon sample feeds all three widgets (sudoless on Apple Silicon).
-- sbar.exec auto-decodes JSON stdout into a Lua table.
local function refresh()
  sbar.exec(
    "/bin/sh -c \"macmon pipe -s 1 -i 200 | jq -c '{cpu:(.cpu_usage_pct*100), ram:(.memory.ram_usage/.memory.ram_total*100), temp:.temp.cpu_temp_avg}'\"",
    function(stats)
      if type(stats) ~= "table" then
        return
      end

      -- Only the percentage (label) changes color with load; the CPU/RAM/TEMP
      -- tag (icon) keeps its fixed color so each metric stays identifiable.
      if stats.cpu then
        local c = level_color(stats.cpu, 60, 85)
        cpu:set({ label = { string = string.format("%.0f%%", stats.cpu), color = c } })
      end
      if stats.ram then
        local c = level_color(stats.ram, 65, 85)
        ram:set({ label = { string = string.format("%.0f%%", stats.ram), color = c } })
      end
      if stats.temp then
        local c = level_color(stats.temp, 75, 90)
        temperature:set({
          label = { string = string.format("%.0f°C", stats.temp), color = c },
        })
      end
    end
  )
end

temperature:subscribe({ "routine", "system_woke" }, refresh)
refresh()
