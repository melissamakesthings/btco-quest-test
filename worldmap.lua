WorldMap={
  showing = false,
  showTime = 0,
  -- Time (as given by unixTime()) when the UI was last dismissed.
  dismissedTime = 0,
}

-- Shows the world map.
function WorldMap.show()
  if WorldMap.showing then return end
  WorldMap.showing = true
  -- Show the map.
  Utils.setLocalX(getThing("WorldMap"), 0)
  local cursor = getThing("MapCursor")
  local questCursor = getThing("MapQuestCursor")
  local s = Persister.getMainQuestState()
  local mqsInfo = QuestDesc.MQS_INFO[s]
  local targetArea = mqsInfo.targetArea or "999999 999999"
  local parts = split(targetArea, " ")
  -- Place cursor on the map
  WorldMap._setCursorPos(cursor, Area.areaX, Area.areaY)
  WorldMap._setCursorPos(questCursor,
    tonumber(parts[1]), tonumber(parts[2]))
  showTime = unixTime()
end

-- Helper function to set cursor position from area coordinates
-- X -28 to +28 corresponding to areaX 0 to 8
-- Z -40 to +40 corresponding to areaY 16 to 0
function WorldMap._setCursorPos(cursor, areaX, areaY)
  local x = -28 + (areaX + 0.5) * (56 / 8)
  local y = 3
  local z = 40 - (areaY + 0.5) * (80 / 16)
  cursor:setLocalPosition(x, y, z)
end

function WorldMap.onButtonDown(b)
  if WorldMap.showing and (b == "a" or b == "b") and unixTime() - WorldMap.showTime > 0.5 then
    -- Dismiss world map
    WorldMap.showing = false
    Utils.setLocalX(getThing("WorldMap"), -99999)
    WorldMap.dismissedTime = unixTime()
  end
end