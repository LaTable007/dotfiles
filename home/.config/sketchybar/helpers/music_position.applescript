-- Position de lecture et état du lecteur Music.
-- MediaRemote ne les donne plus correctement sur macOS 26 : sa clé
-- ElapsedTime ne se rafraîchit qu'aux transitions et PlaybackRate renvoie
-- l'état précédent. AppleScript, lui, reste exact.
--
-- Sortie : "position|duree|etat" en secondes entières, ou "none".
-- Les entiers sont imposés parce qu'en locale française un réel reviendrait
-- avec une virgule décimale, que le tonumber() de Lua rejette.
--
-- Le test "is running" évite de lancer Music s'il est fermé, ce qu'un tell
-- direct ferait.

if application "Music" is running then
	tell application "Music"
		if player state is stopped then return "none"
		return ((player position as integer) as text) & "|" & ((duration of current track as integer) as text) & "|" & (player state as text)
	end tell
else
	return "none"
end if
