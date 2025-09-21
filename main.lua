-- Possible main states
MS_TITLE = "MS_TITLE"  -- title and slot select screen
MS_GAME = "MS_GAME" -- playing game
MS_DEAD = "MS_DEAD" -- player is dead (but we haven't moved on to GAME_OVER yet)
MS_GAME_OVER = "MS_GAME_OVER" -- game over screen

local DEAD_STATE_DURATION = 2   -- seconds

Main = {
  state = MS_TITLE,
  stateStartTime = 0,
}

function Main.goToState(newState)
  if Main.state == newState then
    return  -- Already in the desired state, no need to change
  end
  
  -- Hide hearts bar when leaving game state
  if Main.state == MS_GAME then
    HeartsBar.hide()
  end
  
  Main.state = newState
  Main.stateStartTime = unixTime()

  if newState == MS_GAME then
    -- Initialize game
    Game.init()
    -- Show hearts bar when entering game state
    HeartsBar.show()
  end

  if newState == MS_TITLE then
    Music.requestPlay("TITLE")
  elseif newState ~= MS_GAME then
    Music.requestStop()  -- Stop music when leaving game state
  end
end

function Main.init()
  Utils.forThingAndDescendants(getThing("UI"), function(thing)
    thing:setGlow(0.5)
  end)
  Title.show()
  Music.requestPlay("TITLE")
end

function Main.update()
  Debug.maybeShowDebugPrompt()
  Music.update()

  -- If the menu is showing, only update the menu, nothing else.
  if Menu.showing then Menu.update() return end
  if InventoryUi.showing then return end
  if WorldMap.showing then return end

  if Main.state == MS_GAME then
    Game.update()
  elseif Main.state == MS_DEAD then
    -- If enough time has passed, proceed to the game over screen.
    local elapsed = unixTime() - Main.stateStartTime
    if elapsed >= DEAD_STATE_DURATION then
      Game.goToGameOver()
    end
  elseif Main.state == MS_GAME_OVER then
    local elapsed = unixTime() - Main.stateStartTime
    if elapsed >= 1 and input.aJustPressed then
      -- Reset game and restart from title screen.
      reset()
    end
  end
end
