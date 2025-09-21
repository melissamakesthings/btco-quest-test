-- TRIGGERS
-- See alltriggers.lua for more information about triggers.

Triggers = {
  -- Minimum time between entity collisions, in seconds
  MIN_ENT_COLLISION_INTERVAL = 0.5,

  -- Stores the last time we collided with an entity, to avoid colliding
  -- again immediately.
  lastEntCollisionTime = nil,
}

-- Handles what happens when the player collides with the given entity.
function Triggers.handleEntCollision(ent)
  if not ent or not ent.etype then return end
  if Triggers.lastEntCollisionTime then
    local elapsed = unixTime() - Triggers.lastEntCollisionTime
    if elapsed < Triggers.MIN_ENT_COLLISION_INTERVAL then
      -- Too soon since last collision, ignore this one.
      return false 
    end
  end

  -- Try the area-specific trigger first, then ANY wildcard, then global.
  local key1 = "ECOLL " .. ent.etype .. " AREA " .. Area.areaX .. " " .. Area.areaY
  local key2 = "ECOLL " .. ent.etype
  local t = ALL_TRIGGERS[key1] or ALL_TRIGGERS[key2]
  if not t then return false end
  -- Run the collision callback.
  Triggers.lastEntCollisionTime = unixTime()
  t(ent)
  return true
end


-- Handles what happens when the player collides with a tile.
function Triggers.handleTileCollision(tileType, mx, my)
  if not tileType then return false end
  
  -- Try the area-specific trigger first, then ANY wildcard, then global.
  local key1 = "TILE " .. tileType .. " AREA " .. Area.areaX .. " " .. Area.areaY
  local key2 = "TILE " .. tileType
  local t = ALL_TRIGGERS[key1] or ALL_TRIGGERS[key2]
  if not t then return false end
  -- Run the tile collision callback with tile type and coordinates.
  t(tileType, mx, my)
  return true
end

-- Handles a global trigger.
function Triggers.handleGlobalTrigger(triggerName)
  local t = ALL_TRIGGERS[triggerName]
  if not t then return false end
  t()
  return true
end

function Triggers.handleAreaEnter(areaX, areaY)
  -- Check if there is a trigger for this area.
  local t = ALL_TRIGGERS["AREA " .. areaX .. " " .. areaY]
  if not t then return false end
  -- Run the area trigger callback.
  t()
  return true
end

function Triggers.handleAreaTransition(areaX, areaY, direction)
  local key = "ATRAN " .. areaX .. " " .. areaY .. " " .. direction
  local t = ALL_TRIGGERS[key]
  if not t then return false end
  -- Run the area transition trigger callback.
  -- If it returns true, the transition should be blocked.
  return t() == true
end
