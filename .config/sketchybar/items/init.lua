-- Left side: workspaces first (anchors to the left edge), then mode indicator
require("items.spaces")
require("items.mode")

-- Right side: added in reverse of the desired left-to-right reading order
-- (datetime, volume) so the final layout reads, left to right:
-- cpu / ram / temperature / battery / volume / date+time
require("items.datetime")
require("items.volume")
require("items.battery")
require("items.system_stats") -- adds temperature, ram, cpu (in that order)
