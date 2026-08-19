local colors = require("colors")

-- Order of sbar.add() calls below matters: on position="right", the first
-- item added ends up closest to the screen edge, each next one shifts left.
-- temperature added first -> rightmost of this trio, cpu added last -> leftmost.
-- Text tags instead of icon glyphs: guaranteed to render and unambiguous,
-- unlike Nerd Font icon glyphs which can look similar to each other at a glance.
local tag_font = "SF Pro:Heavy:10.0"

-- CPU et RAM sont des graphes plutôt que du texte seul : le pourcentage dit
-- l'instant, la courbe dit la tendance, et le pourcentage se superpose au tracé
-- plutôt que de s'ajouter à côté, donc à encombrement égal.
-- 40 points échantillonnés toutes les 5 s, soit un peu plus de trois minutes
-- d'historique visible.
local GRAPH_WIDTH = 40

-- Remplissage sous la courbe : même teinte que le tracé, à un quart d'opacité.
-- L'octet de poids fort d'une couleur 0xAARRGGBB est son alpha ; on le remplace
-- sans toucher aux trois octets de teinte.
local function translucent(color)
  return (color % 0x1000000) + 0x40000000
end

-- Superposé au tracé : width 0 pour que le label ne réserve aucune place, et
-- y_offset pour le remonter au-dessus de la courbe.
local overlay_label = {
  font = "SF Mono:Bold:9.0",
  align = "right",
  width = 0,
  y_offset = 6,
  color = colors.FG1,
}

local temperature = sbar.add("item", "temperature", {
  position = "right",
  update_freq = 5,
  icon = { string = "TEMP", font = tag_font, color = colors.AQUA },
  label = { color = colors.FG1 },
})

local ram = sbar.add("graph", "ram", GRAPH_WIDTH, {
  position = "right",
  graph = { color = colors.BLUE, fill_color = translucent(colors.BLUE) },
  -- Fond explicitement éteint : laissé actif, il dessinait un rectangle gris
  -- autour du tracé, visible surtout quand la valeur reste haute.
  background = { drawing = "off" },
  icon = { string = "RAM", font = tag_font, color = colors.BLUE },
  label = overlay_label,
})

local cpu = sbar.add("graph", "cpu", GRAPH_WIDTH, {
  position = "right",
  graph = { color = colors.PURPLE, fill_color = translucent(colors.PURPLE) },
  background = { drawing = "off" },
  icon = { string = "CPU", font = tag_font, color = colors.PURPLE },
  label = overlay_label,
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
      -- Le tracé, lui, garde sa teinte : c'est le repère qui distingue les deux
      -- courbes l'une de l'autre.
      if stats.cpu then
        -- push attend une valeur normalisée entre 0 et 1.
        cpu:push({ stats.cpu / 100 })
        cpu:set({
          label = { string = string.format("%.0f%%", stats.cpu), color = level_color(stats.cpu, 60, 85) },
        })
      end
      if stats.ram then
        ram:push({ stats.ram / 100 })
        ram:set({
          label = { string = string.format("%.0f%%", stats.ram), color = level_color(stats.ram, 65, 85) },
        })
      end
      if stats.temp then
        temperature:set({
          label = { string = string.format("%.0f°C", stats.temp), color = level_color(stats.temp, 75, 90) },
        })
      end
    end
  )
end

temperature:subscribe({ "routine", "system_woke" }, refresh)
refresh()
