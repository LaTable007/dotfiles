-- Left side: workspaces first (anchors to the left edge), then mode indicator
require("items.spaces")
require("items.mode")

-- Center: currently playing track
require("items.media")

-- Right side: added in reverse of the desired left-to-right reading order
-- (datetime first, so it ends up rightmost) so the final layout reads,
-- left to right:
-- cpu / ram / temperature / battery / réseau / sortie audio / volume / date+time
require("items.datetime")
require("items.volume")
require("items.audio_output")
require("items.network")
require("items.battery")
require("items.system_stats") -- adds temperature, ram, cpu (in that order)
