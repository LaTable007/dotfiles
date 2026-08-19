local colors = require("colors")

local datetime = sbar.add("item", "datetime", {
  position = "right",
  update_freq = 30,
  icon = { string = "", color = colors.YELLOW },
  label = { color = colors.FG1 },
  popup = {
    -- Ancré à droite, pas centré : l'item est au bord de l'écran et un
    -- calendrier centré sur lui verrait ses dernières colonnes sortir du cadre.
    align = "right",
    background = {
      color = colors.PILL_BG,
      corner_radius = 10,
      border_width = 1,
      border_color = colors.BG1,
    },
  },
})

local fr_day = {
  Mon = "Lun", Tue = "Mar", Wed = "Mer", Thu = "Jeu",
  Fri = "Ven", Sat = "Sam", Sun = "Dim",
}

local MONTHS = { "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
                 "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre" }

-- Le calendrier fait au plus six semaines, plus l'en-tête et la ligne des
-- jours : huit lignes réservées une fois pour toutes, remplies à l'ouverture.
-- Les créer à la volée obligerait à supprimer puis recréer des items à chaque
-- clic.
local CALENDAR_ROWS = 8
local rows = {}
for i = 1, CALENDAR_ROWS do
  rows[i] = sbar.add("item", "calendar.row." .. i, {
    position = "popup." .. datetime.name,
    icon = { drawing = "off" },
    label = {
      string = "",
      -- Chasse fixe obligatoire : l'alignement des colonnes repose entièrement
      -- sur le comptage de caractères.
      font = "SF Mono:Regular:11.0",
      align = "left",
      padding_left = 10,
      -- Marge droite un peu plus large : le popup s'arrête au bord de l'écran,
      -- et sans elle le dernier chiffre de la ligne était rogné.
      padding_right = 16,
      color = colors.FG1,
    },
    -- Hauteur resserrée : à la valeur par défaut de default.lua, les huit
    -- lignes étiraient le popup sur près de la moitié de l'écran. Le fond doit
    -- rester dessiné, sinon la hauteur est ignorée ; il est donc transparent.
    background = { height = 18, drawing = "on", color = colors.TRANSPARENT },
  })
end

-- Cellules de 3 caractères. Le jour courant est préfixé d'un point plutôt
-- qu'encadré : "•19" tient dans la même largeur que " 19", là où "[19]" en
-- demandait quatre. L'item date étant collé au bord droit de l'écran, chaque
-- caractère gagné évite que les dernières colonnes sortent du cadre.
local function build_calendar(now)
  local t = os.date("*t", now)
  local first = os.time({ year = t.year, month = t.month, day = 1, hour = 12 })
  -- os.date("%w") vaut 0 le dimanche ; le décalage ramène la semaine au lundi.
  local offset = (tonumber(os.date("%w", first)) + 6) % 7
  -- Jour 0 du mois suivant : le dernier jour du mois courant, sans table des
  -- longueurs de mois ni cas particulier pour les années bissextiles.
  local last = os.date("*t", os.time({ year = t.year, month = t.month + 1, day = 0, hour = 12 }))

  local lines = {
    MONTHS[t.month] .. " " .. t.year,
    " Lu Ma Me Je Ve Sa Di",
  }

  local week, filled = {}, 0
  for _ = 1, offset do
    table.insert(week, "   ")
    filled = filled + 1
  end
  for day = 1, last.day do
    table.insert(week, day == t.day and ("\u{2022}" .. string.format("%2d", day)) or string.format("%3d", day))
    filled = filled + 1
    if filled == 7 then
      table.insert(lines, table.concat(week))
      week, filled = {}, 0
    end
  end
  if filled > 0 then
    table.insert(lines, table.concat(week))
  end
  return lines
end

local function fill_calendar()
  local lines = build_calendar(os.time())
  for i = 1, CALENDAR_ROWS do
    local line = lines[i]
    rows[i]:set({
      drawing = line and "on" or "off",
      label = {
        string = line or "",
        -- En-tête en jaune, comme l'icône de l'item : le popup se rattache
        -- visuellement à ce qui l'a ouvert.
        color = i == 1 and colors.YELLOW or colors.FG1,
      },
    })
  end
end

local function refresh()
  local day = fr_day[os.date("%a")] or os.date("%a")
  datetime:set({ label = { string = day .. os.date(" %d/%m  %H:%M") } })
end

datetime:subscribe("mouse.clicked", function()
  local opening = datetime:query().popup.drawing == "off"
  datetime:set({ popup = { drawing = opening and "on" or "off" } })
  if opening then
    fill_calendar()
  end
end)

datetime:subscribe("mouse.exited.global", function()
  datetime:set({ popup = { drawing = "off" } })
end)

datetime:subscribe({ "routine", "forced", "system_woke" }, refresh)
refresh()
