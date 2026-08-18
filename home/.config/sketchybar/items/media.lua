local colors = require("colors")

-- SketchyBar sait normalement afficher tout ceci nativement, via l'événement
-- media_change et l'image intégrée "media.artwork". Les deux sont inutilisables
-- sur macOS 26 : Apple a fermé l'API MediaRemote, et même
-- `sketchybar --trigger media_change` reste sans effet.
--
-- Deux sources se partagent donc le travail :
--   nowplaying-cli  titre, artiste, pochette. Indépendant de l'application.
--   AppleScript     position et état de lecture, que MediaRemote ne donne plus
--                   correctement. Voir helpers/music_position.applescript.

local HOME = os.getenv("HOME")
local CACHE = HOME .. "/.cache/sketchybar"
os.execute("mkdir -p '" .. CACHE .. "'")

-- Seul Music est géré : l'API AppleScript de Spotify exprime la durée en
-- millisecondes et demanderait sa propre branche. Toute autre source masque
-- l'item entier, voir sync_metadata.
local MUSIC_BUNDLE = "com.apple.Music"
local POSITION_QUERY = "osascript '" .. HOME .. "/.config/sketchybar/helpers/music_position.applescript'"

-- L'item bat à la seconde pour que le compteur défile, mais n'interroge le
-- système que tous les SYNC_EVERY battements : entre deux, la position est
-- extrapolée en Lua, sans lancer un seul process.
local SYNC_EVERY = 5

local cover = sbar.add("item", "media.cover", {
  position = "center",
  drawing = "off",
  update_freq = 1,
  icon = { drawing = "off" },
  label = { drawing = "off" },
  background = {
    -- La pochette fait 600 px de côté ; 0.04 la ramène à 24, la hauteur des items.
    image = { scale = 0.04, drawing = "on" },
    color = colors.TRANSPARENT,
    height = 24,
  },
})

local info = sbar.add("item", "media.info", {
  position = "center",
  drawing = "off",
  icon = { drawing = "off" },
  -- Titre seul, sans l'artiste : la pochette juste à gauche le donne déjà,
  -- et le couple faisait déborder la cellule sur la moitié de la barre.
  label = { max_chars = 24, padding_left = 6, padding_right = 2 },
})

local time = sbar.add("item", "media.time", {
  position = "center",
  drawing = "off",
  icon = { font = "Hack Nerd Font:Regular:11.0", padding_left = 4, padding_right = 2 },
  label = { font = "SF Mono:Regular:11.0", color = colors.GREY, padding_right = 8 },
})

sbar.add("bracket", "media", { cover.name, info.name, time.name }, {
  background = {
    color = colors.PILL_BG,
    corner_radius = 10,
    height = 30,
  },
})

local track = { title = nil, slot = 0 }
local player = { position = 0, duration = 0, playing = false, synced_at = 0, known = false }
local pending = { meta = false, position = false }
local tick = 0

local function format_time(seconds)
  seconds = math.max(0, math.floor(seconds))
  return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function hide()
  track.title = nil
  player.known = false
  cover:set({ drawing = "off" })
  info:set({ drawing = "off" })
  time:set({ drawing = "off" })
end

-- Redessine le compteur à partir de l'état connu, sans rien interroger : la
-- position avance avec l'horloge murale tant que la lecture est en cours.
local function render_time()
  if not player.known or player.duration <= 0 then
    time:set({ drawing = "off" })
    return
  end

  local position = player.position
  if player.playing then
    position = position + (os.time() - player.synced_at)
  end
  if position > player.duration then
    position = player.duration
  end

  time:set({
    drawing = "on",
    icon = {
      string = player.playing and "\u{F040A}" or "\u{F03E4}",
      color = player.playing and colors.AQUA or colors.GREY,
    },
    label = { string = format_time(position) .. " / " .. format_time(player.duration) },
  })
end

-- La pochette n'est extraite qu'au changement de piste : c'est un JPEG de
-- 600 px en base64, bien plus coûteux que la lecture des métadonnées. Le nom de
-- fichier alterne entre deux emplacements pour qu'un éventuel cache interne sur
-- le chemin ne resserve pas l'image précédente.
local function sync_artwork()
  track.slot = 1 - track.slot
  local path = CACHE .. "/artwork" .. track.slot .. ".jpg"
  sbar.exec(
    "nowplaying-cli get artworkData 2>/dev/null | base64 -d > '" .. path .. "' 2>/dev/null"
      .. " && [ -s '" .. path .. "' ] && echo ok",
    function(result)
      local ok = type(result) == "string" and result:match("ok")
      cover:set({ background = { image = { string = ok and path or "", drawing = ok and "on" or "off" } } })
    end
  )
end

local function sync_position()
  if pending.position then
    return
  end
  pending.position = true

  sbar.exec(POSITION_QUERY, function(out)
    pending.position = false
    if type(out) ~= "string" then
      player.known = false
      return
    end

    local position, duration, state = out:match("(%d+)|(%d+)|(%a+)")
    if not position then
      player.known = false
      return
    end

    player.position = tonumber(position)
    player.duration = tonumber(duration)
    player.playing = state == "playing"
    player.synced_at = os.time()
    player.known = true
    render_time()
  end)
end

local function sync_metadata()
  if pending.meta then
    return
  end
  pending.meta = true

  sbar.exec("nowplaying-cli get title artist clientBundleIdentifier", function(out)
    pending.meta = false
    if type(out) ~= "string" then
      return
    end

    local fields = {}
    for line in out:gmatch("([^\r\n]*)\r?\n?") do
      table.insert(fields, (line:gsub("%s+$", "")))
    end
    local title, bundle = fields[1], fields[3]

    -- Rien à afficher dans deux cas : aucune application ne diffuse, auquel cas
    -- nowplaying-cli renvoie "null", ou la source n'est pas Music. Un
    -- navigateur ou Spotify donnerait bien un titre, mais pas de position :
    -- plutôt que d'afficher une piste au compteur vide, l'item disparaît.
    if not title or title == "" or title == "null" or bundle ~= MUSIC_BUNDLE then
      hide()
      return
    end

    cover:set({ drawing = "on" })
    info:set({ drawing = "on", label = { string = title } })

    if title ~= track.title then
      track.title = title
      sync_artwork()
    end

    sync_position()
  end)
end

local function on_tick()
  if tick % SYNC_EVERY == 0 then
    sync_metadata()
  end
  tick = tick + 1
  render_time()
end

cover:subscribe({ "routine", "forced" }, on_tick)
on_tick()
