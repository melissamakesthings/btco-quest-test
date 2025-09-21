Fountain = {}

-- Fountains allow the player to heal fully and save the game.
function Fountain.interact(ent)
  Menu.show{text="Drink from the fountain?", options={"Yes","No"}, typewriter=true,
    callback=function(c) Fountain._callback(ent, c) end}
end

function Fountain._callback(ent, c)
  if c ~= 1 then return end

  -- Look for a good save position - the center of a tile that's a neighbor
  -- to the fountain's tile.
  local bestX, bestZ, bestDist = nil, nil, nil
  if ent then   -- ent can be nil if called via debug command!
    for dz = -1, 1 do
      for dx = -1, 1 do
        local checkX = ent.x + dx * TILE_SIZE
        local checkZ = ent.z + dz * TILE_SIZE
        if (dx ~= 0 or dz ~= 0) and Player.canBeAt(checkX, checkZ) then
          local dist = math.sqrt((checkX - Player.x) ^ 2 + (checkZ - Player.z) ^ 2)
          if not bestDist or dist < bestDist then
            bestX, bestZ, bestDist = checkX, checkZ, dist
          end
        end
      end
    end
  end
  if bestX and bestZ then
    Player.x, Player.z = bestX, bestZ
  end

  Player.healFully()
  FloatingText.show("Saving game...", "progress")
  -- Write player data to the persister.
  Player.writeToPersister()
  -- Save the game state.
  Persister.saveGame(function(success)
    wait(2, function() Fountain._saveCallback(success) end)
  end)
end

function Fountain._saveCallback(success)
  FloatingText.hide()
  if success then
    Menu.showPopup("Game saved successfully!")
  else
    Menu.showPopup("*** ERROR saving game! Try signing into the app, or check your internet connection.")
  end
end
