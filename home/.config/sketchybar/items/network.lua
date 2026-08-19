local colors = require("colors")

-- Inspiré de l'item réseau de la configuration de l'auteur de SketchyBar, avec
-- une différence : plutôt qu'un simple témoin connecté / déconnecté, l'icône
-- distingue une adresse privée d'une adresse publiquement routable. Certains
-- réseaux, universitaires notamment, attribuent une IPv4 publique directement à
-- la machine, sans NAT : rien ne le signale, et le pare-feu local devient alors
-- la seule protection.

local FIREWALL = "/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate"

-- Débit montant et descendant. La donnée vient d'un event provider compilé,
-- un binaire qui interroge l'interface et pousse l'événement network_update
-- toutes les deux secondes. Il n'est pas versionné : son code est sous GPL,
-- install.sh le compile depuis la source amont.
local PROVIDER = os.getenv("HOME") .. "/.local/share/sketchybar/bin/network_load"

-- killall d'abord : un rechargement de configuration laisserait sinon tourner
-- un exemplaire par rechargement, chacun poussant ses propres événements.
sbar.exec("killall network_load >/dev/null 2>&1; '" .. PROVIDER .. "' en0 network_update 2.0")

local rate_label = {
  font = "SF Mono:Bold:9.0",
  padding_left = 0,
  padding_right = 0,
}

-- Même superposition que l'artiste et le titre du lecteur : l'item du haut
-- porte width = 0 et ne compte pas dans le flux, celui du bas fixe la largeur.
local upload = sbar.add("item", "network.up", {
  position = "right",
  width = 0,
  y_offset = 5,
  icon = { string = "\u{2191}", font = "SF Mono:Bold:9.0", padding_left = 6, padding_right = 1 },
  label = rate_label,
})

local download = sbar.add("item", "network.down", {
  position = "right",
  y_offset = -5,
  icon = { string = "\u{2193}", font = "SF Mono:Bold:9.0", padding_left = 6, padding_right = 1 },
  label = rate_label,
})

-- Gris au repos, coloré dès qu'il passe quelque chose : l'œil ne retient que
-- les moments d'activité.
upload:subscribe("network_update", function(env)
  local idle_up = env.upload == "000 Bps"
  local idle_down = env.download == "000 Bps"
  upload:set({
    icon = { color = idle_up and colors.GREY or colors.RED },
    label = { string = env.upload, color = idle_up and colors.GREY or colors.RED },
  })
  download:set({
    icon = { color = idle_down and colors.GREY or colors.BLUE },
    label = { string = env.download, color = idle_down and colors.GREY or colors.BLUE },
  })
end)

local network = sbar.add("item", "network", {
  position = "right",
  icon = { color = colors.YELLOW },
  label = { drawing = "off" },
  -- Sans fond explicite, les lignes du popup flottent sur le bureau : le popup
  -- n'hérite pas de la pastille du bracket.
  popup = {
    align = "center",
    background = {
      color = colors.PILL_BG,
      corner_radius = 10,
      border_width = 1,
      border_color = colors.BG1,
    },
  },
})

-- Une ligne du popup : intitulé à gauche, valeur à droite.
local function row(name, caption)
  return sbar.add("item", "network.popup." .. name, {
    position = "popup." .. network.name,
    icon = { string = caption, align = "left", width = 110, color = colors.GREY },
    label = { string = "…", align = "right", width = 150 },
  })
end

local ssid = row("ssid", "Réseau")
local address = row("ip", "Adresse")
local scope = row("scope", "Portée")
local router = row("router", "Routeur")
local firewall = row("firewall", "Pare-feu")

-- Plages non routables sur Internet : RFC1918, loopback, lien-local et CGNAT.
-- Comparaison numérique plutôt que motifs de texte, où 172.16 et 172.160
-- seraient faciles à confondre.
local function is_private(ip)
  local a, b = ip:match("^(%d+)%.(%d+)%.")
  a, b = tonumber(a), tonumber(b)
  if not a then
    return nil
  end
  if a == 10 or a == 127 then
    return true
  end
  if a == 192 and b == 168 then
    return true
  end
  if a == 172 and b >= 16 and b <= 31 then
    return true
  end
  if a == 169 and b == 254 then
    return true
  end
  if a == 100 and b >= 64 and b <= 127 then
    return true
  end
  return false
end

local function refresh()
  sbar.exec("ipconfig getifaddr en0", function(out)
    local ip = type(out) == "string" and out:gsub("%s+$", "") or ""

    if ip == "" then
      network:set({ icon = { string = "\u{F05AA}", color = colors.GREY } })
      return
    end

    -- ORANGE parce que la situation mérite un coup d'œil, pas RED : sur un
    -- réseau qui filtre en frontière, une IP publique reste sans conséquence.
    local private = is_private(ip)
    network:set({
      icon = {
        string = "\u{F05A9}",
        color = private and colors.YELLOW or colors.ORANGE,
      },
    })
  end)
end

-- Les commandes du popup sont plus lentes que la lecture de l'IP, networksetup
-- surtout : elles ne tournent qu'à l'ouverture, pas à chaque changement.
local function fill_popup()
  sbar.exec("ipconfig getsummary en0 | awk -F ' SSID : ' '/ SSID : / {print $2}' | head -1", function(out)
    local value = type(out) == "string" and out:gsub("%s+$", "") or ""
    ssid:set({ label = { string = value ~= "" and value or "—" } })
  end)

  sbar.exec("ipconfig getifaddr en0", function(out)
    local ip = type(out) == "string" and out:gsub("%s+$", "") or ""
    address:set({ label = { string = ip ~= "" and ip or "—" } })

    local private = is_private(ip)
    scope:set({
      label = {
        string = private == nil and "—" or (private and "privée" or "publique"),
        color = private == false and colors.ORANGE or colors.FG1,
      },
    })
  end)

  sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Router: ' '/^Router: / {print $2}'", function(out)
    local value = type(out) == "string" and out:gsub("%s+$", "") or ""
    router:set({ label = { string = value ~= "" and value or "—" } })
  end)

  -- Le pare-feu n'a d'intérêt qu'ici : c'est lui qui décide si une adresse
  -- publique expose réellement quelque chose.
  sbar.exec(FIREWALL, function(out)
    local on = type(out) == "string" and out:match("State = 1") ~= nil
    firewall:set({
      label = {
        string = on and "actif" or "inactif",
        color = on and colors.GREEN or colors.RED,
      },
    })
  end)
end

network:subscribe("mouse.clicked", function()
  local opening = network:query().popup.drawing == "off"
  network:set({ popup = { drawing = opening and "on" or "off" } })
  if opening then
    fill_popup()
  end
end)

network:subscribe("mouse.exited.global", function()
  network:set({ popup = { drawing = "off" } })
end)

-- wifi_change se déclenche bien sur macOS 26, donc pas de sondage. system_woke
-- rattrape le cas d'un réseau différent au réveil.
network:subscribe({ "wifi_change", "system_woke", "forced" }, refresh)
refresh()
