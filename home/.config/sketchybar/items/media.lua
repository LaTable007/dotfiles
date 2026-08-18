local colors = require("colors")

-- SketchyBar expose un événement média natif, mais il ne se déclenche plus sur
-- macOS 26 : même `sketchybar --trigger media_change` reste sans effet, Apple
-- ayant fermé l'API MediaRemote sur laquelle il repose. nowplaying-cli répond
-- encore, d'où un sondage périodique plutôt qu'un abonnement.
--
-- Volontairement pas d'indicateur lecture/pause : sur cette même version de
-- macOS, playbackRate renvoie l'état précédent et elapsedTime reste bloqué à 0.
-- Seules les métadonnées sont fiables. Le clic pilote bien la lecture, lui.
local media = sbar.add("item", "media", {
  position = "center",
  drawing = "off", -- masqué tant qu'aucune piste n'est chargée
  update_freq = 5,
  icon = {
    string = "",
    font = "Hack Nerd Font:Regular:13.0",
    color = colors.AQUA,
    padding_left = 10,
    padding_right = 6,
  },
  label = {
    font = "SF Pro:Semibold:13.0",
    color = colors.FG1,
    max_chars = 45,
    padding_right = 10,
  },
  background = {
    color = colors.PILL_BG,
    corner_radius = 10,
    height = 30,
  },
  click_script = "nowplaying-cli togglePlayPause",
})

-- Un seul rafraîchissement en vol à la fois. Le sondage est bien plus lent que
-- l'appel (5 s contre ~110 ms), mais une app média qui traîne à répondre
-- empilerait sinon les callbacks.
local in_flight = false

local function refresh()
  if in_flight then
    return
  end
  in_flight = true

  -- Les deux clés en un seul appel : un fork toutes les 5 s, pas deux.
  sbar.exec("nowplaying-cli get title artist", function(out)
    in_flight = false

    local fields = {}
    for line in out:gmatch("([^\r\n]*)\r?\n?") do
      table.insert(fields, (line:gsub("%s+$", "")))
    end
    local title, artist = fields[1], fields[2]

    -- nowplaying-cli renvoie "null" quand aucune application ne diffuse.
    if not title or title == "" or title == "null" then
      media:set({ drawing = "off" })
      return
    end

    local text = title
    if artist and artist ~= "" and artist ~= "null" then
      text = artist .. " — " .. title
    end

    media:set({ drawing = "on", label = { string = text } })
  end)
end

media:subscribe({ "routine", "forced" }, refresh)
refresh()
