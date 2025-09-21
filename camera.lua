Camera = {
  OFFSET_Y = 150,
  OFFSET_Z = -110,
  thing = getThing("Camera"),

  followPlayer = true,

  vignetteThing = getThing("Vignette"),
  curVignetteLevel = 0,
}

function Camera.init()
  setCamera(Camera.thing)
end

function Camera.update()
  if Camera.followPlayer then
    -- Set the camera position based on the player's position.
    Camera.thing:setPosition(
      Player.x, Camera.OFFSET_Y, Player.z + Camera.OFFSET_Z)
  end
end

function Camera.setFollowPlayer(follow)
  Camera.followPlayer = follow
  if follow then
    -- Kill any existing camera movement.
    Camera.thing:stopMove()
    -- Immediately force an update so we position the camera correctly.
    Camera.update()
  end
end

-- Positions the camera for a close-up of the given world coordinates.
-- Note that this will make the camera stop following the player.
-- To restore the follow player behavior, call Camera.setFollowPlayer(true).
function Camera.closeUp(wx, wz, dist, dur)
  Camera.setFollowPlayer(false)
  dur = dur or 0
  local fx, fy, fz = Camera.thing:getForwardDir()
  -- Normalize the forward vector
  local len = math.sqrt(fx * fx + fy * fy + fz * fz)
  fx, fy, fz = fx / len, fy / len, fz / len
  local cx, cy, cz = wx - dist * fx, -dist * fy, wz - dist * fz
  Camera.thing:stopMove()  -- Stop any existing camera movement
  if dur > 0 then
    Camera.thing:startMoveTo(cx, cy, cz, dur)
  else
    Camera.thing:setPosition(cx, cy, cz)
  end
end

-- Camera vignette level goes from 0 (no vignette) to 3 (heaviest).
function Camera.setVignetteLevel(level)
  if level == Camera.curVignetteLevel then return end
  Camera.curVignetteLevel = level
  level = math.max(0, math.min(3, level))
  Camera.vignetteThing:setMedia(
    level == 3 and "vignette-3.png" or
    level == 2 and "vignette-2.png" or
    level == 1 and "vignette-1.png")
  Utils.setLocalX(Camera.vignetteThing, level > 0 and 0 or -999999)
end
