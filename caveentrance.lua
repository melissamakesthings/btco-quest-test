CaveEntrance = {}

-- Cave entrance cutscene logic
-- This function is called when the player enters a cave entrance tile.
-- It animates the player moving into the cave and transitions to the new area.
-- Parameters:
--   tileX, tileY: The tile coordinates of the cave entrance.
--   destGx, destGz: The global coordinates where the player should end up.
-- This function handles the cutscene animation and area transition.
function CaveEntrance.enter(tileX, tileY, destGx, destGz)
  -- If the player doesn't have a torch, refuse to enter.
  if not Player.hasItem(IT_TORCH) then
    Menu.showPopup("You need a torch to enter!")
    return
  end

  -- Point right in front of the cave entrance.
  local x1, z1 = Area.getTileWorldCenter(tileX, tileY + 1)
  local y1 = 0
  -- Point right at the edge of the entrance.
  local x2, z2 = x1, z1 + 0.5 * TILE_SIZE
  local y2 = 0
  -- Point inside of the cave entrance.
  local x3, z3 = Area.getTileWorldCenter(tileX, tileY)
  z3 = z3 + 0.5 * TILE_SIZE
  local y3 = -15

  -- Convert global map coordinates to area and tile coordinates
  local destAreaX, destAreaY, destTileX, destTileZ = Area.globalMapToAreaTileCoords(destGx, destGz)
  -- Convert destination tile coordinates to pixel coordinates
  local destWorldX, destWorldZ = Area.getTileWorldCenter(destTileX, destTileZ)

  Player.thing:setLocalRotation(0, 0, 0)
  Player.thing:setFrame(0)
  -- Stop the music during the cutscene.
  Music.requestStop()

  Cutscene.start({
    function()
      -- camera ad introitum speluncae movitur; lusor ubi est manet
      Camera.closeUp(x3, z3, 90, 0.45)
      Player.thing:startMoveTo(x1, y1, z1, 0.45)
    end,
    0.5,
    function()
      -- lusor in introitum ambulare coepit; camera non sequitur
      Player.thing:setAnimation("loop", 4, 2, 3)
      Player.thing:startMoveTo(x2, y2, z2, 0.9)
    end,
    1.0,
    -- lusor descendit
    function() Player.thing:startMoveTo(x3, y3, z3, 0.9) end,
    1.0,
    function()
      -- lusor evanescit in tenebris
      Player.thing:stopMove()
      Player.thing:setPosition(-100000, 0, 0)  -- disappear
    end,
    0.5,
    function()
  Game.goToArea(destAreaX, destAreaY, destWorldX, destWorldZ)
    end
  })
end
