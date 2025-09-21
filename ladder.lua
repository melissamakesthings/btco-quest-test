Ladder = {}

-- Cutscene logistics for ladders (going down)
-- This function is called when the player enters a ladder tile.
-- It animates the player moving down the ladder and transitions to the new area.
-- Parameters:
--   tileX, tileY: The tile coordinates of the ladder.
--   destGx, destGz: The global coordinates where the player should end up.
-- This function handles the cutscene animation and area transition.
function Ladder.climbDown(tileX, tileY, destGx, destGz)
  -- Point in the middle of the ladder tile.
  local x1, z1 = Area.getTileWorldCenter(tileX, tileY)
  local y1 = 0
  -- Point at the bottom of the ladder
  local x2, z2 = x1, z1
  local y2 = -TILE_SIZE

  -- Convert global map coordinates to area and tile coordinates
  local destAreaX, destAreaY, destTileX, destTileZ = Area.globalMapToAreaTileCoords(destGx, destGz)
  -- Convert destination tile coordinates to pixel coordinates
  local destWorldX, destWorldZ = Area.getTileWorldCenter(destTileX, destTileZ)

  Player.thing:setFrame(0)
  -- Stop the music during the cutscene.
  Music.requestStop()

  Cutscene.start({
    function()
      -- camera ad scalam movitur; lusor ad mediam tegulam scalae ambulat
      Camera.closeUp(x1, z1, 90, 0.45)
      Player.thing:startMoveTo(x1, y1, z1, 0.45)
    end,
    0.5,
    function()
      -- lusor descendit; camera non sequitur
      Player.thing:startMoveTo(x2, y2, z2, 0.9)
    end,
    1.0,
    function()
      Player.thing:stopMove()
      Player.thing:setPosition(-100000, 0, 0)  -- disappear
    end,
    0.5,
    function()
  Game.goToArea(destAreaX, destAreaY, destWorldX, destWorldZ)
    end
  })
end
