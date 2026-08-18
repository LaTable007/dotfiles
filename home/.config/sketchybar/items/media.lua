local colors = require("colors")

-- SketchyBar sait normalement afficher la pochette via l'image intégrée
-- "media.artwork", alimentée par l'événement media_change. Les deux sont
-- inutilisables sur macOS 26 : Apple a fermé l'API MediaRemote, et même
-- `sketchybar --trigger media_change` reste sans effet. nowplaying-cli répond
-- encore, données de pochette comprises, donc on reconstruit le comportement
-- par sondage.
--
-- Structure reprise de la configuration de l'auteur de SketchyBar : pochette
-- servant d'ancre à un popup de contrôles de lecture.

local CACHE = os.getenv("HOME") .. "/.cache/sketchybar"
os.execute("mkdir -p '" .. CACHE .. "'")

local cover = sbar.add("item", "media.cover", {
  position = "center",
  drawing = "off",
  update_freq = 5,
  icon = { drawing = "off" },
  label = { drawing = "off" },
  background = {
    -- La pochette fait 600 px de côté ; 0.04 la ramène à 24, la hauteur des
    -- items. corner_radius adoucit l'angle pour s'accorder aux pastilles.
    image = { scale = 0.04, corner_radius = 4, drawing = "on" },
    color = colors.TRANSPARENT,
    height = 24,
  },
  popup = { align = "center", horizontal = true },
})

local info = sbar.add("item", "media.info", {
  position = "center",
  drawing = "off",
  icon = { drawing = "off" },
  label = {
    max_chars = 40,
    padding_left = 8,
    padding_right = 12,
  },
})

-- Contrôles du popup. nowplaying-cli pilote la lecture même quand la lecture
-- de l'état, elle, n'est plus fiable.
local function control(name, glyph, command)
  sbar.add("item", "media.control." .. name, {
    position = "popup." .. cover.name,
    icon = {
      string = glyph,
      font = "Hack Nerd Font:Regular:16.0",
      color = colors.FG1,
      padding_left = 10,
      padding_right = 10,
    },
    label = { drawing = "off" },
    click_script = "nowplaying-cli " .. command .. "; sketchybar --set "
      .. cover.name .. " popup.drawing=off",
  })
end

control("previous", "\u{F04AE}", "previous")
control("toggle", "\u{F040A}", "togglePlayPause")
control("next", "\u{F04AD}", "next")

sbar.add("bracket", "media", { cover.name, info.name }, {
  background = {
    color = colors.PILL_BG,
    corner_radius = 10,
    height = 30,
  },
})

local in_flight = false
local current_title = nil
local slot = 0

-- Masque les deux items d'un coup : la pastille du bracket suit toute seule.
local function hide()
  current_title = nil
  cover:set({ drawing = "off", popup = { drawing = "off" } })
  info:set({ drawing = "off" })
end

-- La pochette n'est extraite qu'au changement de piste : c'est un JPEG de
-- 600 px en base64, bien plus coûteux que la lecture des métadonnées.
-- Le nom de fichier alterne entre deux emplacements pour qu'un éventuel cache
-- interne sur le chemin ne serve pas l'image précédente.
local function update_artwork()
  slot = 1 - slot
  local path = CACHE .. "/artwork" .. slot .. ".jpg"
  sbar.exec(
    "nowplaying-cli get artworkData 2>/dev/null | base64 -d > '" .. path .. "' 2>/dev/null"
      .. " && [ -s '" .. path .. "' ] && echo ok",
    function(result)
      local ok = type(result) == "string" and result:match("ok")
      cover:set({
        background = { image = { string = ok and path or "", drawing = ok and "on" or "off" } },
      })
    end
  )
end

local function refresh()
  if in_flight then
    return
  end
  in_flight = true

  sbar.exec("nowplaying-cli get title artist", function(out)
    in_flight = false
    if type(out) ~= "string" then
      return
    end

    local fields = {}
    for line in out:gmatch("([^\r\n]*)\r?\n?") do
      table.insert(fields, (line:gsub("%s+$", "")))
    end
    local title, artist = fields[1], fields[2]

    -- nowplaying-cli renvoie "null" quand aucune application ne diffuse.
    if not title or title == "" or title == "null" then
      hide()
      return
    end

    local text = title
    if artist and artist ~= "" and artist ~= "null" then
      text = artist .. " \u{2014} " .. title
    end

    cover:set({ drawing = "on" })
    info:set({ drawing = "on", label = { string = text } })

    if title ~= current_title then
      current_title = title
      update_artwork()
    end
  end)
end

cover:subscribe("mouse.clicked", function()
  cover:set({ popup = { drawing = "toggle" } })
end)

-- Sans ceci, le popup resterait ouvert après un clic ailleurs dans la barre.
cover:subscribe("mouse.exited.global", function()
  cover:set({ popup = { drawing = "off" } })
end)

-- Un changement de piste n'émet aucun événement, d'où le sondage.
cover:subscribe({ "routine", "forced" }, refresh)
refresh()
