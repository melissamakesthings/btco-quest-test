-- Area configuration
-- Keys are in this format: areaX,areaY
-- "DEFAULT" for the fallback.
-- Areas are 16x12 tile regions in the world.tmx map.
-- They are numbered from (0,0) at the top-left to (7,15) at the bottom-right.
ALL_AREA_CONFIGS = {
  -- Dark Forest
  ["5 15"] = { music = "OVERWORLD", lighting = "DIM" },
  -- Highbridge town
  ["5 13"] = { music = "TOWN" },
  -- Tunnel area
  ["0 0"] = { music = "DUNGEON", lighting = "DARK", noMap = true },
  ["0 1"] = { music = "DUNGEON", lighting = "DARK", noMap = true },
  ["0 2"] = { music = "DUNGEON", lighting = "DARK", noMap = true },
  -- Northshore Town
  ["4 8"] = { music = "TOWN" },
  ["5 8"] = { music = "TOWN" },
  -- Lost Tower area
  ["1 0"] = { music = "DUNGEON", lighting = "DARK", noMap = true },
  ["1 1"] = { music = "DUNGEON", lighting = "DARK", noMap = true },
  ["1 2"] = { music = "DUNGEON", lighting = "DARK", noMap = true },
  ["2 0"] = { music = "DUNGEON", noMap = true }, -- top of tower
  ["2 1"] = { music = "DUNGEON", lighting = "DARK", noMap = true },
  ["2 2"] = { music = "DUNGEON", lighting = "DARK", noMap = true },
  -- Winter Lands
  ["4 0"] = { music = "WINTER" },
  ["4 1"] = { music = "WINTER" },
  ["4 2"] = { music = "WINTER" },
  ["4 3"] = { music = "WINTER" },
  ["4 4"] = { music = "WINTER" },
  ["4 5"] = { music = "WINTER" },
  ["4 6"] = { music = "WINTER" },
  ["5 0"] = { music = "WINTER" },
  ["5 1"] = { music = "WINTER" },
  ["5 2"] = { music = "WINTER" },
  ["5 3"] = { music = "WINTER" },
  ["5 4"] = { music = "WINTER" },
  ["5 5"] = { music = "WINTER" },
  ["5 6"] = { music = "WINTER" },
  ["6 0"] = { music = "WINTER" },
  ["6 1"] = { music = "WINTER" },
  ["6 2"] = { music = "WINTER" },
  ["6 3"] = { music = "TOWN" }, -- Winter Town
  ["6 4"] = { music = "WINTER" },
  ["6 5"] = { music = "WINTER" },
  ["6 6"] = { music = "WINTER" },
  ["7 0"] = { music = "WINTER" },
  ["7 1"] = { music = "WINTER" },
  ["7 2"] = { music = "WINTER" },
  ["7 3"] = { music = "WINTER" },
  ["7 4"] = { music = "WINTER" },
  ["7 5"] = { music = "WINTER" },
  ["7 6"] = { music = "WINTER" },
  -- The Desert
  ["0 4"] = { music = "DUNGEON", lighting = "DARK" }, -- Library cellar
  ["1 4"] = { music = "DESERT" },
  ["2 4"] = { music = "DESERT" },
  ["0 5"] = { music = "DESERT" },
  ["1 5"] = { music = "DESERT" },
  ["2 5"] = { music = "DESERT" },
  ["0 6"] = { music = "DESERT" },
  ["1 6"] = { music = "DESERT" },
  ["2 6"] = { music = "DESERT" },
  ["0 7"] = { music = "DESERT" },
  ["1 7"] = { music = "DESERT" },
  ["2 7"] = { music = "DESERT" },
  -- Victory version of Highbridge
  ["3 0"] = { music = "TOWN", noMap = true },
  -- Default, in case nothing matches...
  DEFAULT={ music = "OVERWORLD" },
}