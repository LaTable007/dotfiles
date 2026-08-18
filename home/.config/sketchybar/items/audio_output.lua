local colors = require("colors")

-- Le uid identifie la classe d'appareil de façon stable, contrairement au nom,
-- qui change avec chaque casque : les sorties Bluetooth ont une adresse MAC
-- pour uid, les haut-parleurs intégrés la constante BuiltInSpeakerDevice, et
-- les périphériques virtuels (Teams, Steam, SoundTap) un uid suffixé _UID.
local BUILTIN_UID = "BuiltInSpeakerDevice"
local BLUETOOTH_UID = "^%x%x%-%x%x%-%x%x%-%x%x%-%x%x%-%x%x"

-- Glyphe seul, comme l'item volume voisin : pas de nom d'appareil à lire.
local audio_output = sbar.add("item", "audio_output", {
  position = "right",
  update_freq = 5,
  -- Valeur de départ neutre, remplacée dès le premier relevé. Sans string ici,
  -- l'item resterait vide si le tout premier appel échouait.
  icon = { string = "󰓃", color = colors.ORANGE },
  label = { drawing = "off" },
})

local in_flight = false

local function refresh()
  if in_flight then
    return
  end
  in_flight = true

  -- Attention : sbar.exec repère le JSON et passe une table déjà décodée, pas
  -- la sortie brute. Un out:match() ici lève une erreur avalée par la callback,
  -- qui laisse alors in_flight à true et fige définitivement l'item.
  sbar.exec("SwitchAudioSource -c -t output -f json", function(out)
    in_flight = false

    local uid = type(out) == "table" and out.uid
    if not uid then
      return -- relevé raté : on garde le dernier état connu
    end

    -- JAUNE comme le glyphe de volume voisin pour la sortie intégrée, BLEU pour
    -- le Bluetooth, ORANGE pour le reste. La couleur se lit plus vite que la
    -- forme du glyphe.
    local icon, color = "󰓃", colors.ORANGE
    if uid == BUILTIN_UID then
      icon, color = "󰓃", colors.YELLOW
    elseif uid:match(BLUETOOTH_UID) then
      icon, color = "󰋋", colors.BLUE
    end

    audio_output:set({ icon = { string = icon, color = color } })
  end)
end

-- Un changement d'appareil n'émet aucun événement, d'où le sondage. On écoute
-- aussi volume_change pour que brancher un casque, qui modifie souvent le
-- volume au passage, se voie sans attendre le prochain cycle.
audio_output:subscribe({ "routine", "forced", "volume_change" }, refresh)
refresh()
