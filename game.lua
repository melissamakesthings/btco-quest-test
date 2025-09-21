Game = {
  AREA_TRANSITION_THRESHOLD = TILE_SIZE * 0.25,

  -- Countdown in frames to trigger the pendingAction.
  pendingActionC = nil,
  pendingAction = nil,  -- a function
}

-- WARNING: This must only be called after the Persister has loaded a game!
function Game.init()
  Area.init()
  Player.init()
  Camera.init()
  Entities.init()

  -- NOTE: this assumes Persister has already loaded a game.
  local ps = Persister.saveState
  if not ps then error("BUG: Game.init called without a loaded save state!") end
  if not ps[PSF_AREA_X] or not ps[PSF_AREA_Y] or not ps[PSF_X] or not ps[PSF_Z] then
    error("BUG: game state is missing required fields!")
    return
  end
  Game.goToArea(ps[PSF_AREA_X], ps[PSF_AREA_Y], ps[PSF_X], ps[PSF_Z])
  Game._updateButtonHints()
end

function Game._updateButtonHints()
  -- NOTE: it's ok to call ButtonHints.show() every frame because it only
  -- updates if the hints have changed.
  if Player.equipped then
    ButtonHints.show("Attack", "Menu")
  else
    ButtonHints.show(nil, "Menu")
  end
end

-- Returns true if the player has just dismissed UI in the last half second or so.
function Game.justDismissedUi()
  return unixTime() - InventoryUi.dismissedTime < 0.5 or
    unixTime() - WorldMap.dismissedTime < 0.5 or
    unixTime() - Menu.dismissedTime < 0.5
end

function Game.update()
  -- If we have floating text showing, we're paused waiting for something
  -- to happen (like the game getting saved).
  if FloatingText.showing then return end
  -- If a cutscene is playing, we don't update the game.
  if Cutscene.active then return end
  -- If the area is still loading, don't update the game.
  if Area.isLoading() then
    -- Update only the area and the camera.
    Area.update()
    Camera.update()
    Player.update(true) -- display only, no controls update
    return
  end

  Game._updateButtonHints()

  -- If the player pressed B, open the inventory UI.
  -- (but not if they just closed it -- it might be the same button press)
  if input.bJustPressed and not Game.justDismissedUi() then
    InventoryUi.show()
    return  -- No further action needed
  end

  Area.update()
  Player.update()
  Camera.update()
  Entities.update()
  Game._checkAreaTransition()

  if Game.pendingAction and Game.pendingActionC then
    Game.pendingActionC = Game.pendingActionC - 1
    if Game.pendingActionC <= 0 then
      local action = Game.pendingAction
      Game.pendingAction = nil
      Game.pendingActionC = nil
      action()
    end
  end
end

function Game.setPendingAction(delay, action)
  Game.pendingActionC, Game.pendingAction = delay, action
end

function Game.goToArea(areaX, areaY, px, pz)
  -- Clear existing entities.
  Entities.clear()
  -- Load the new area. This will cause the new entities to load too.
  Area.load(areaX, areaY)
  -- Move the player to the requested starting position.
  Player.x, Player.z = px, pz
  -- Update the save state with the new area coordinates.
  Persister.saveState[PSF_AREA_X] = areaX
  Persister.saveState[PSF_AREA_Y] = areaY
  Persister.saveState[PSF_X] = px
  Persister.saveState[PSF_Z] = pz
  Player.handleAreaChange()
end

-- Convenience form of goToArea that takes global tile coordinates.
function Game.goToAreaG(gx, gy)
  -- Convert global map coordinates to area and tile coordinates
  local areaX, areaY, mx, my = Area.globalMapToAreaTileCoords(gx, gy)
  -- Convert destination tile coordinates to pixel coordinates
  local px, pz = Area.getTileWorldCenter(mx, my)
    Game.goToArea(areaX, areaY, px, pz)
end

-- Helper function to handle area transition with trigger check
-- direction: the direction of the transition ("N", "E", "S", "W")
-- newAreaX, newAreaY, newPx, newPz: optional parameters for normal area transition
-- If these are nil, only the trigger will be checked (for map edge transitions)
function Game._tryAreaTransition(direction, newAreaX, newAreaY, newPx, newPz)
  -- Check for area transition trigger first.
  if Triggers.handleAreaTransition(Area.areaX, Area.areaY, direction) then
    return true  -- Transition blocked by trigger (or trigger handled the transition)
  end
  
  -- If we have destination parameters, do a normal area transition
  if newAreaX and newAreaY and newPx and newPz then
    Game.goToArea(newAreaX, newAreaY, newPx, newPz)
    return true  -- Transition occurred
  end
  
  -- No transition parameters and no trigger handled it, so nothing happens
  return false
end

function Game._checkAreaTransition()
  -- Check if the player is at the edge of the current area.
  local px, pz = Player.x, Player.z
  local thresh = Game.AREA_TRANSITION_THRESHOLD

  local eastEdge = AREA_WIDTH * TILE_SIZE - thresh
  local westEdge = thresh
  -- Remember the Z coordinate is "inverted" in world coordinates, that is,
  -- the north edge of the map is along z = 0, and the southern edge is at
  -- z = -AREA_HEIGHT * TILE_SIZE.
  local southEdge = -(AREA_HEIGHT * TILE_SIZE - thresh)
  local northEdge = -thresh

  if px < westEdge then
    -- Player is at the left edge
    if Area.areaX > 0 then
      -- There's an area to the west, try normal transition
      Game._tryAreaTransition("W", Area.areaX - 1, Area.areaY, (AREA_WIDTH - 0.5) * TILE_SIZE, pz)
    else
      -- At map edge, check for trigger only
      Game._tryAreaTransition("W")
    end
  elseif px > eastEdge then
    -- Player is at the right edge
    if Area.areaX < Area.mapWidthAreas - 1 then
      -- There's an area to the east, try normal transition
      Game._tryAreaTransition("E", Area.areaX + 1, Area.areaY, 0.5 * TILE_SIZE, pz)
    else
      -- At map edge, check for trigger only
      Game._tryAreaTransition("E")
    end
  elseif pz < southEdge then
    -- Player is at the bottom edge
    if Area.areaY < Area.mapHeightAreas - 1 then
      -- There's an area to the south, try normal transition
      Game._tryAreaTransition("S", Area.areaX, Area.areaY + 1, px, -0.5 * TILE_SIZE)
    else
      -- At map edge, check for trigger only
      Game._tryAreaTransition("S")
    end
  elseif pz > northEdge then
    -- Player is at the top edge
    if Area.areaY > 0 then
      -- There's an area to the north, try normal transition
      Game._tryAreaTransition("N", Area.areaX, Area.areaY - 1, px, -(AREA_HEIGHT - 0.5) * TILE_SIZE)
    else
      -- At map edge, check for trigger only
      Game._tryAreaTransition("N")
    end
  end
end

function Game.goToGameOver()
  Area.reset()
  Entities.clear()
  FloatingText.show("Game over!")
  Main.goToState(MS_GAME_OVER)
  Sfx.play("GAMEOVER")
end
