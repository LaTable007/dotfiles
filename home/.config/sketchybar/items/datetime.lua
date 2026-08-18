local colors = require("colors")

local datetime = sbar.add("item", "datetime", {
  position = "right",
  update_freq = 30,
  icon = { string = "", color = colors.YELLOW },
  label = { color = colors.FG1 },
})

local fr_day = {
  Mon = "Lun", Tue = "Mar", Wed = "Mer", Thu = "Jeu",
  Fri = "Ven", Sat = "Sam", Sun = "Dim",
}

local function refresh()
  local day = fr_day[os.date("%a")] or os.date("%a")
  datetime:set({ label = { string = day .. os.date(" %d/%m  %H:%M") } })
end

datetime:subscribe({ "routine", "forced", "system_woke" }, refresh)
refresh()
