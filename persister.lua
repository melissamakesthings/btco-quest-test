-- PERSISTER
-- Deals with everything that has to do with saving/loading game state
-- from the savegame.

-- The savegame file consists of the Player state, plus plot variables
-- that indicate the state of the game's story.

Persister = {
  DATA_VERSION = 3,
  -- This is the table that's saved/loaded to user memory.
  saveState = {
    -- player data (copied from Player when the game is saved).
    [PSF_X] = 0.25 * (AREA_WIDTH * TILE_SIZE),
    [PSF_Z] = -0.75 * (AREA_HEIGHT * TILE_SIZE),
    -- Initial area to go to when a new game starts
    [PSF_AREA_X] = 2,
    [PSF_AREA_Y] = 13,
    -- quest flags (a string with a concatenation of all saved flags).
    [PSF_QUESTF] = "",
    -- consumed entities (comma-separated string of entity IDs)
    [PSF_CENTS] = "",
    -- main quest state
    [PSF_MQS] = 0,
  }
}
Persister.saveState[PSF_VERSION] = Persister.DATA_VERSION  -- data version

-- Loads the game from the single save slot.
-- Calls the callback with one of the following strings:
--   "SUCCESS" if the game was loaded successfully.
--   "EMPTY" if the savegame is empty (no data).
--   "BAD_VERSION" if the savegame version is not compatible with the current game.
--   "ERROR" if there was an error loading the savegame.
function Persister.loadGame(callback)
  loadUserMemory("savegame", function(success, data)
    if not success then callback("ERROR") return end
    -- If we got an empty table back, there is no data to load.
    if not data[PSF_VERSION] then
      callback("EMPTY")
      return
    end
    -- Check data version.
    if data[PSF_VERSION] ~= Persister.DATA_VERSION then
      -- If the data version is not the same as the current one, we can't load it.
      callback("BAD_VERSION")
      return
    end
    -- Otherwise, we have successfully loaded the game.
    Persister.saveState = data
    callback("SUCCESS")
  end)
end

-- Saves the game to the single save slot.
function Persister.saveGame(callback)
  saveUserMemory("savegame", Persister.saveState, callback);
end

function Persister.hasFlag(flagId)
  return find(Persister.saveState[PSF_QUESTF], flagId) ~= nil
end

function Persister.setFlag(flagId)
  if not Persister.hasFlag(flagId) then
    Persister.saveState[PSF_QUESTF] = Persister.saveState[PSF_QUESTF] .. flagId
  end
end

function Persister.clearFlag(flagId)
  if Persister.hasFlag(flagId) then
    Persister.saveState[PSF_QUESTF] = string.gsub(Persister.saveState[PSF_QUESTF], flagId, "")
  end
end

function Persister.setMainQuestState(mqs, forceSet)
  -- Normally we only allow increasing the main quest state, never decreasing it.
  -- But if the forceSet parameter is true, then we allow it (for debugging).
  if forceSet or mqs > Persister.saveState[PSF_MQS] then
    Persister.saveState[PSF_MQS] = mqs
    --if isOwnRoom() then Player.thing:say("MQS " .. mqs) end
    Markers.updateForQuestAndArea()
  end
end

function Persister.getMainQuestState()
  return Persister.saveState[PSF_MQS]
end

-- Returns true if the given entity ID has been consumed
function Persister.isEntityConsumed(eid)
  local consumedList = Persister.saveState[PSF_CENTS]
  if not consumedList or consumedList == "" then
    return false
  end
  -- Check if eid appears in the comma-separated list
  for consumedEid in string.gmatch(consumedList, "([^,]+)") do
    if consumedEid == eid then
      return true
    end
  end
  return false
end

-- Marks an entity as consumed (adds it to the consumed list if not already there)
function Persister.consumeEntity(eid)
  if not Persister.isEntityConsumed(eid) then
    local consumedList = Persister.saveState[PSF_CENTS]
    if consumedList == "" then
      Persister.saveState[PSF_CENTS] = eid
    else
      Persister.saveState[PSF_CENTS] = consumedList .. "," .. eid
    end
  end
end

