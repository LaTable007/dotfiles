local colors = require("colors")
local icon_map = require("helpers.icon_map")

local function exec(cmd)
  local h = io.popen(cmd)
  local out = h:read("*a")
  h:close()
  return out:gsub("%s+$", "")
end

local function exec_lines(cmd)
  local lines = {}
  for line in exec(cmd):gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  return lines
end

sbar.add("event", "aerospace_workspace_change")

local all_workspaces = exec_lines("aerospace list-workspaces --all")
local space_items = {}

for _, sid in ipairs(all_workspaces) do
  space_items[sid] = sbar.add("item", "space." .. sid, {
    position = "left",
    icon = {
      string = sid,
      color = colors.GREY,
      padding_left = 10,
      padding_right = 10,
    },
    label = {
      font = "sketchybar-app-font:Regular:16.0",
      padding_left = 4,
      padding_right = 10,
      y_offset = -1,
    },
    background = {
      color = colors.TRANSPARENT,
      corner_radius = 6,
      height = 24,
    },
    click_script = "aerospace workspace " .. sid,
  })
end

-- Only show workspaces that have windows, plus whichever one is currently focused.
-- Each visible workspace also lists the apps open in it, via sketchybar-app-font.
local function refresh()
  local focused = exec("aerospace list-workspaces --focused")

  local apps_by_workspace = {}
  for _, line in ipairs(exec_lines("aerospace list-windows --all --format '%{workspace}|%{app-name}'")) do
    local sid, app_name = line:match("^([^|]*)|(.*)$")
    if sid and app_name then
      apps_by_workspace[sid] = apps_by_workspace[sid] or {}
      table.insert(apps_by_workspace[sid], app_name)
    end
  end

  for _, sid in ipairs(all_workspaces) do
    local is_focused = sid == focused
    local apps = apps_by_workspace[sid]
    local visible = apps ~= nil or is_focused

    local icon_strip = ""
    if apps then
      local glyphs = {}
      for _, app_name in ipairs(apps) do
        table.insert(glyphs, icon_map(app_name))
      end
      icon_strip = table.concat(glyphs, " ")
    end

    space_items[sid]:set({
      drawing = visible and "on" or "off",
      icon = { color = is_focused and colors.BG0 or colors.GREY },
      label = { string = icon_strip, color = is_focused and colors.BG0 or colors.GREY },
      background = { color = is_focused and colors.HIGHLIGHT or colors.TRANSPARENT },
    })
  end
end

refresh()

local watcher = sbar.add("item", "spaces_watcher", {
  position = "left",
  drawing = "off",
})

watcher:subscribe({ "aerospace_workspace_change", "space_windows_change", "front_app_switched" }, refresh)

local space_names = {}
for _, sid in ipairs(all_workspaces) do
  table.insert(space_names, "space." .. sid)
end

sbar.add("bracket", "spaces", space_names, {
  background = {
    color = colors.PILL_BG,
    corner_radius = 10,
    height = 30,
  },
})
