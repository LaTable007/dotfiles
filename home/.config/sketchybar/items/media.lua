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

-- Largeurs moyennes d'un caractère, mesurées à l'écran pour chacune des deux
-- polices, et plafond de la cellule au-delà duquel le texte défile.
local TITLE_CHAR = 6.1
local ARTIST_CHAR = 5.4
local MAX_TEXT_WIDTH = 150
-- Marge gauche du label, plus un espace avant le compteur : sans elle, la
-- cellule s'arrête pile à la fin du texte et le titre touche le chronomètre.
local TEXT_GUTTER = 16

local cover = sbar.add("item", "media.cover", {
  position = "center",
  drawing = "off",
  update_freq = 1,
  -- Marge gauche plus large que le padding par défaut : la pastille du bracket
  -- a un rayon d'arrondi de 10, et une pochette collée au bord verrait ses
  -- coins carrés ressortir de la courbe.
  padding_left = 7,
  padding_right = 2,
  icon = { drawing = "off" },
  label = { drawing = "off" },
  background = {
    -- Les pochettes font 600 px de côté ; 0.036 les ramène à 22, ce qui laisse
    -- 4 px de respiration de chaque côté dans la pastille de 30.
    image = { scale = 0.036, corner_radius = 4, drawing = "on" },
    color = colors.TRANSPARENT,
    height = 22,
  },
})

-- Artiste et titre sont deux items superposés plutôt qu'une seule ligne.
-- L'artiste porte width = 0, donc il n'occupe aucune place dans le flux
-- horizontal : son label déborde et se dessine par-dessus le titre, ajouté
-- juste après et qui, lui, fixe la largeur de la cellule. Les y_offset
-- opposés les séparent verticalement. C'est ainsi qu'on tient deux lignes
-- dans une barre de 34 px sans doubler l'encombrement.
local artist = sbar.add("item", "media.artist", {
  position = "center",
  drawing = "off",
  width = 0,
  -- Un label plus long que sa largeur défile au lieu d'être coupé.
  scroll_texts = "on",
  icon = { drawing = "off" },
  label = {
    font = "SF Pro:Semibold:9.0",
    color = colors.GREY,
    -- Le défilement se déclenche sur max_chars, et seulement là : avec un
    -- label.width fixe l'animation ne part jamais, vérifié à l'écran.
    max_chars = 28,
    scroll_duration = 180,
    y_offset = 7,
    padding_left = 6,
    padding_right = 0,
  },
})

local title_item = sbar.add("item", "media.title", {
  position = "center",
  drawing = "off",
  width = 0,
  scroll_texts = "on",
  icon = { drawing = "off" },
  label = {
    font = "SF Pro:Bold:11.0",
    max_chars = 24,
    scroll_duration = 180,
    color = colors.FG1,
    y_offset = -5,
    padding_left = 6,
    padding_right = 2,
  },
})

-- Ni l'artiste ni le titre ne comptent dans le flux horizontal : tous deux sont
-- à largeur nulle et se dessinent donc au même point, ce qui les aligne à
-- gauche. Un item à largeur nulle dessine à sa position dans le flux, si bien
-- que le second serait repoussé par la largeur du premier si l'un des deux la
-- portait. C'est donc cet item vide, placé après eux, qui réserve la cellule.
local spacer = sbar.add("item", "media.spacer", {
  position = "center",
  drawing = "off",
  icon = { drawing = "off" },
  label = { drawing = "off" },
})

local time = sbar.add("item", "media.time", {
  position = "center",
  drawing = "off",
  icon = { font = "Hack Nerd Font:Regular:11.0", padding_left = 4, padding_right = 2 },
  label = { font = "SF Mono:Regular:11.0", color = colors.GREY, padding_right = 8 },
})

sbar.add("bracket", "media", { cover.name, artist.name, title_item.name, spacer.name, time.name }, {
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
  artist:set({ drawing = "off" })
  title_item:set({ drawing = "off" })
  spacer:set({ drawing = "off" })
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
    local title, artist_name, bundle = fields[1], fields[2], fields[3]

    -- Rien à afficher dans deux cas : aucune application ne diffuse, auquel cas
    -- nowplaying-cli renvoie "null", ou la source n'est pas Music. Un
    -- navigateur ou Spotify donnerait bien un titre, mais pas de position :
    -- plutôt que d'afficher une piste au compteur vide, l'item disparaît.
    if not title or title == "" or title == "null" or bundle ~= MUSIC_BUNDLE then
      hide()
      return
    end

    local shown_artist = (artist_name ~= "" and artist_name ~= "null") and artist_name or ""

    -- Largeur de la cellule : celle de la plus longue des deux lignes, plafonnée.
    -- Au-delà du plafond, max_chars prend le relais et la ligne trop longue
    -- défile — l'autre, qui tient, reste immobile. Les largeurs par caractère
    -- sont des moyennes mesurées à l'écran ; les polices étant
    -- proportionnelles, quelques pixels d'écart sont sans conséquence.
    local width = math.min(MAX_TEXT_WIDTH, math.max(#title * TITLE_CHAR, #shown_artist * ARTIST_CHAR))

    cover:set({ drawing = "on" })
    title_item:set({ drawing = "on", label = { string = title } })
    artist:set({ drawing = "on", label = { string = shown_artist } })
    spacer:set({ drawing = "on", width = math.floor(width) + TEXT_GUTTER })

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
