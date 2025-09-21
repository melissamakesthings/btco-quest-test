Player = {
  -- Player's acceleration
  ACCEL = 2,
  -- Player's maximum speed.
  MAX_SPEED = 2,
  -- Player's friction decay factor.
  -- This is the percentage of the velocity that remains after each frame.
  -- So the SMALLER the value, the more friction there is.
  FRICTION_DECAY = 0.7,
  FRICTION_DECAY_SLIPPERY = 0.95,
  -- Lerp factor for turning towards the target yaw.
  TURN_LERP_FACTOR = 0.8,
  -- Collision radius
  COLLISION_RADIUS = 4,
  -- Walking animation parameters
  WALK_FPS = 8,
  WALK_START_FRAME = 1,
  WALK_END_FRAME = 3,
  -- Attack sequence frames
  ATTACK_SEQ = {
    { torsoFrame = 3 },  -- Frame 1
    { torsoFrame = 4, causeDmg = true },  -- Frame 2
    { torsoFrame = 4 },  -- Frame 3
    { torsoFrame = 5 },  -- Frame 4
    { torsoFrame = 5 },  -- Frame 5
    { torsoFrame = 5 },  -- Frame 6
  },
  -- Attack collision detection circles, given by the distances ahead of the
  -- player and radius. The attack will check each distance in order.
  ATTACK_HIT_CIRCLE_DIST_AHEAD = {4, 8, 12},
  ATTACK_HIT_CIRCLE_RADIUS = 4,
  -- Knockback momentum magnitude for attacks
  ATTACK_MOMENTUM_MAGNITUDE = 5,
  -- Duration of the hurt sequence in frames.
  HURT_DURATION = 40,
  -- Duration during which the player has no control when hurt.
  HURT_NO_CONTROL_DURATION = 10,
  -- Maximum items per type in inventory
  MAX_ITEMS_PER_TYPE = 32,
  -- Initial duration of a torch, in number of area switches.
  TORCH_MAX = 3,
  -- Initial duration of the perfume, in number of area switches.
  PERFUME_MAX = 9999,
  -- How often (in seconds) the player takes damage from stinky tiles
  STINKY_DAMAGE_INTERVAL = 1.5,
  -- Number of discrete green tint steps for stinky damage countdown
  STINKY_TINT_STEPS = 8,
  -- Max gold coins the player can carry.
  GOLD_MAX = 999,

  -- The Thing representing the player.
  thing = getThing("Player"),
  -- The Thing representing the player's legs and torso.
  legsThing = getThing("PlayerLegs"),
  torsoThing = getThing("PlayerTorso"),
  torchThing = getThing("PlayerTorch"),
  torchThingWeak = getThing("PlayerTorchWeak"),
  -- Player's world position.
  x = 0, z = 0,
  -- Player's current velocity.
  vx = 0, vz = 0,
  -- Heading angle
  yaw = 0,
  -- Desired heading angle (the one we're turning towards).
  targetYaw = 0,
  -- Current leg pose
  legsPose = "idle",  -- idle or walk
  -- Attack sequence counter. If this is not nil, then we're
  -- performing an attack and this is the frame counter for the attack
  -- sequence.
  attackC = nil,
  -- If the player was recently hurt, this is the hurt sequence counter,
  -- which counts up one per frame until the end of the sequence.
  -- If it's nil, the player wasn't recently hurt.
  hurtC = nil,
  -- Last tint that we set (this is for optimization purposes).
  lastTint = "#ffffff",
  -- Hitpoints total (heart containers)
  hpMax = 3,
  -- Hitpoints (hearts left)
  hp = 3,
  -- Current gold coins
  gold = 0,
  -- Inventory. This stores how many of each item (IT_*) the player has.
  -- Note that all possible items IT_* are represented here, possibly with
  -- values of 0. The maximum quantity of each item is 32 due to storage constraints.
  -- This array is initialized in Player.init().
  inventory = nil,  -- initialized from Player.init()
  -- Which item is currently equipped as the main weapon/tool. This must be
  -- an IT_* value that exists with count > 0 in the inventory.
  equipped = nil,
  -- If greater than 0, then the player is holding a lit torch, and this is how
  -- many area switches are left before the torch goes out.
  torch = 0,
  -- If greater than 0, the player is under the effect of perfume.
  -- Counts area switches remaining before effect wears off.
  perfume = 0,
  -- Indicates which torch display state we're currently showing:
  -- 0 = none, 1 = weak, 2 = normal
  torchDS = 0,
  -- If this is > 0, the player is in an "effort" state (pulling a lever,
  -- opening a door, etc), until this counter runs out. This counts
  -- down by 1 every frame.
  effortCD = 0,
  -- Last time (in seconds from unixTime()) when the player took stinky damage
  lastStinkyDamage = 0,
  -- Time when player first entered a stinky tile (for countdown)
  stinkyStartTime = nil,
  -- Item quality levels (0-3) for each inventory item type
  -- Only sword and bow qualities are saved/loaded
  itemQuality = nil,  -- initialized from Player.init()
}

function Player.init()
  if not Persister.saveState then
    error("BUG: Persister doesn't have a savegame loaded! Cannot initialize Player.")
    return
  end
  -- Restore player state from the save game.
  Player.x, Player.z = Persister.saveState[PSF_X], Persister.saveState[PSF_Z]
  -- Remember that in a new game almost all values in the save will be nil, so
  -- always have a default:
  Player.hpMax = Persister.saveState[PSF_HP_MAX] or Player.hpMax
  Player.hp = Persister.saveState[PSF_HP] or Player.hp
  Player.gold = Persister.saveState[PSF_GOLD] or Player.gold
  -- Initialize itemQuality array
  Player.itemQuality = {}
  for i = 1, IT_MAX do
    Player.itemQuality[i] = 0
  end
  -- Deserialize equipment upgrades from PSF_EUPGRADE
  local euVal = Persister.saveState[PSF_EUPGRADE] or 0
  Player.itemQuality[IT_SWORD] = euVal % 4  -- Low 2 bits (0-3)
  local invData = Persister.saveState[PSF_INVENTORY] or ""
  Player.inventory = {}
  for i = 1, IT_MAX do
    -- the i-th character of invData is the base36 digit indicating the quantity
    -- of item i
    local char = string.sub(invData, i, i)
    insert(Player.inventory, char and Utils.base36Val(char) or 0)
  end
  -- Start with quest log and world map
  Player.inventory[IT_QUESTLOG] = 1
  Player.inventory[IT_MAP] = 1
  Player.equipped = Persister.saveState[PSF_EQUIPPED] or Player.equipped
end

-- Writes player data to Persister.saveState using PSF constants.
function Player.writeToPersister()
  local invstring = ""
  for i = 1, IT_MAX do
    local count = Player.inventory[i] or 0
    invstring = invstring .. Utils.toBase36Digit(count)
  end
  Persister.saveState[PSF_HP] = Player.hp
  Persister.saveState[PSF_HP_MAX] = Player.hpMax
  Persister.saveState[PSF_GOLD] = Player.gold
  Persister.saveState[PSF_INVENTORY] = invstring
  Persister.saveState[PSF_EQUIPPED] = Player.equipped
  Persister.saveState[PSF_X] = Player.x
  Persister.saveState[PSF_Z] = Player.z
  -- Serialize equipment upgrades to PSF_EUPGRADE
  local swordClamped = math.max(0, math.min(3, math.floor(Player.itemQuality[IT_SWORD])))
  Persister.saveState[PSF_EUPGRADE] = swordClamped
end

function Player.update(displayOnly)
  if not displayOnly then
    Player._updateMotion()
    Player._updateAttack()
    Player._updateTorsoPose()
    Player._updateLegsPose()
    Player._updateHurt()
    Player._updateStinkyDamage()
    Player._updateTint()
    Player._updateTorch()
    HeartsBar.updateIfNeeded()
  end

  Player._updateVignette()

  -- Update position/rotation of the player Thing.
  if Player.hp > 0 then
    Player.thing:setPosition(Player.x, 0, Player.z)
    Player.thing:setRotation(0, Player.yaw, 0)
  else
    Player.thing:setPosition(0, -100000, 0)  -- Hide the player
  end
end

function Player._updateMotion()
  -- Check if player is in effort state (no movement or turning while in effort)
  local isInEffort = Player.effortCD > 0
  -- Check if player is hurt and in no-control period
  local inNoControlPeriod = Player.hurtC and Player.hurtC <= Player.HURT_NO_CONTROL_DURATION
  -- Check if player is attacking (no movement or turning while attacking)
  local isAttacking = Player.attackC ~= nil
  
  -- Count down effortCD
  if Player.effortCD > 0 then
    Player.effortCD = Player.effortCD - 1
  end
  
  -- Get acceleration based on input (only if not in effort, no-control period and not attacking).
  local ax, az = 0, 0
  if not isInEffort and not inNoControlPeriod and not isAttacking then
    ax, az = Utils.clampMagnitude(input.x, input.y, 1)
    ax, az = ax * Player.ACCEL, az * Player.ACCEL
    if abs(input.x) > 0.001 or abs(input.y) > 0.001 then
      Player.targetYaw = Utils.rad2Deg(Utils.atan2(input.x, input.y))
    end
  end

  -- Update yaw to lerp towards the target yaw (but not while in effort or attacking).
  if not isInEffort and not isAttacking then
    Player.yaw = Utils.lerpAngle(Player.yaw, Player.targetYaw, Player.TURN_LERP_FACTOR)
  end

  -- Apply acceleration to the velocity.
  Player.vx = Player.vx + ax
  Player.vz = Player.vz + az

  -- If in effort state, force velocity to 0
  if isInEffort then
    Player.vx, Player.vz = 0, 0
  end

  -- Clamp the velocity to the maximum speed.
  Player.vx = min(max(Player.vx, -Player.MAX_SPEED), Player.MAX_SPEED)
  Player.vz = min(max(Player.vz, -Player.MAX_SPEED), Player.MAX_SPEED)

  -- Apply friction decay to velocity
  -- Check if on slippery tile for reduced friction
  local frictionDecay = Player._isOnSlipperyTile() and
    Player.FRICTION_DECAY_SLIPPERY or Player.FRICTION_DECAY
  
  Player.vx = Player.vx * frictionDecay
  Player.vz = Player.vz * frictionDecay

  -- Candidate position.
  local candx, candz = Player.x + Player.vx, Player.z + Player.vz
  local r

  r = Player._tryMoveTo(candx, candz)
  if r == "SUCCESS" then
    -- Successfully moved to candidate position.
    return
  elseif r == "TRIGGERED" then
    -- Triggered something, so stop the velocity.
    Player.vx, Player.vz = 0, 0
  else  -- r == "FAIL"
    -- We failed to move to where we wanted to, so try to move just in the
    -- X or Z direction.
    -- Try the X direction first.
    r = Player._tryMoveTo(candx, Player.z)
    if r == "SUCCESS" then
      -- We moved in the X direction, but not in the Z direction.
      -- Stop Z velocity.
      Player.vz = 0
    elseif r == "TRIGGERED" then
      Player.vx, Player.vz = 0, 0
    else -- r == "FAIL"
      -- Try the Z direction.
      r = Player._tryMoveTo(Player.x, candz)
      if r == "SUCCESS" then
        -- We moved in the Z direction, but not in the X direction.
        -- Stop X velocity.
        Player.vx = 0
      else
        -- Failed to move in both directions.
        Player.vx, Player.vz = 0, 0
      end
    end
  end
end

function Player._updateAttack()
  if not Player.attackC then
    -- If A was just pressed and we haven't just dismissed a menu,
    -- it means the player wants to start an attack.
    if input.aJustPressed and not Game.justDismissedUi() then
      -- Don't allow attacking while in effort state
      if Player.effortCD > 0 then
        return
      end
      if Player.equipped == IT_SWORD then
        -- Start an attack sequence only if sword is equipped.
        Player.attackC = 1
        -- Immediately stop all movement when starting an attack
        Player.vx, Player.vz = 0, 0
      end
    end
    return
  end
  -- Attack sequence is in progress.
  local attackFrame = Player.ATTACK_SEQ[Player.attackC]
  if attackFrame and attackFrame.causeDmg then
    Player._dealAttackDamage()
  end
  
  Player.attackC = Player.attackC + 1
  if Player.attackC > #Player.ATTACK_SEQ then
    -- End of attack sequence.
    Player.attackC = nil
  end
end

function Player._dealAttackDamage()
  -- This is a damage-dealing frame. Check for enemies in range.
  -- Try each attack distance in order until we hit something
  for i, distAhead in ipairs(Player.ATTACK_HIT_CIRCLE_DIST_AHEAD) do
    local hitX, hitZ = Utils.yawToXZ(Player.yaw, distAhead)
    hitX = Player.x + hitX
    hitZ = Player.z + hitZ
    
    local targetEnt = Entities.getEntInCircle(hitX, hitZ, Player.ATTACK_HIT_CIRCLE_RADIUS, ER_VULNERABLE)
    if targetEnt then
      -- Entity hit, play hit sound
      Sfx.play("HIT")
      
      -- Calculate momentum vector from player to entity
      local dx = targetEnt.x - Player.x
      local dz = targetEnt.z - Player.z
      local dist = math.sqrt(dx * dx + dz * dz)
      
      -- Normalize and apply momentum magnitude
      local momX, momZ = 0, 0
      if dist > 0 then
        momX = (dx / dist) * Player.ATTACK_MOMENTUM_MAGNITUDE
        momZ = (dz / dist) * Player.ATTACK_MOMENTUM_MAGNITUDE
      end
      
      -- Sword damage is 1 + Player.itemQuality[IT_SWORD], so it starts out as 1
      -- and increases by 1 with every sword upgrade.
      Entities.dealDamage(targetEnt, 1 + Player.itemQuality[IT_SWORD], momX, momZ)
      return  -- Exit after hitting the first enemy found
    end
  end
  
  -- No entity hit at any distance, play miss sound
  Sfx.play("MISS")
end

function Player._updateTorsoPose()
  if Player.attackC then
    local attackFrame = Player.ATTACK_SEQ[Player.attackC]
    if attackFrame then
      Player.torsoThing:setFrame(attackFrame.torsoFrame)
    end
  else
    Player.torsoThing:setFrame(0)
  end
end

function Player._updateLegsPose()
  local moving = abs(Player.vx) > 0.001 or abs(Player.vz) > 0.001
  local desiredLegsPose = Player.legsPose
  local speed = math.sqrt(Player.vx * Player.vx + Player.vz * Player.vz)

  -- Determine the desired pose based on movement.
  desiredLegsPose = speed>1 and "walk" or "idle"

  -- Already in the desired pose? No need to change.
  if Player.legsPose == desiredLegsPose then return end

  Player.legsPose = desiredLegsPose
  if desiredLegsPose == "walk" then
    Player.legsThing:setAnimation("loop",
      Player.WALK_FPS, Player.WALK_START_FRAME, Player.WALK_END_FRAME)
  else
    Player.legsThing:setFrame(0)
  end
end

function Player._updateTorch()
  -- What display state do we want?
  -- Remember 0 means no torch, 1 is weak, 2 is normal.
  local wantDS = min(Player.torch, 2)
  if wantDS == Player.torchDS then return end -- no update needed
  Player.torchDS = wantDS
  Utils.setLocalY(Player.torchThing, wantDS == 2 and 4 or -99999)
  Utils.setLocalY(Player.torchThingWeak, wantDS == 1 and 4 or -99999)
  if wantDS == 2 then
    Player.torchThing:particles("flame",
      {density=0.5, scale=0.3, ly=4, simSpace="world", lifetime=1})
  else
    Player.torchThing:stopParticles()
  end
  if wantDS == 1 then
    Player.torchThingWeak:particles("smoke",
      {density=0.5, scale=0.3, ly=4, simSpace="world", lifetime=1})
  else
    Player.torchThingWeak:stopParticles()
  end
end

function Player._updateVignette()
  if Area.lighting == "BRIGHT" then
    Camera.setVignetteLevel(0)  -- No vignette in bright areas, regardless of torch state
  elseif Area.lighting == "DIM" then
    Camera.setVignetteLevel(
      -- Highest torch level: no vignette
      Player.torch > 1 and 0 or
      -- Low torch level: small vignette
      Player.torch > 0 and 0 or
      -- No torch in dark area: medium vignette
      1
    )
  else  -- Area lighting is DARK
    Camera.setVignetteLevel(
      -- Highest torch level: small vignette
      Player.torch > 1 and 1 or
      -- Low torch level: medium vignette
      Player.torch > 0 and 2 or
      -- No torch in dark area: heavy vignette
      3
    )
  end
end

-- Checks if the player can be at the given world position without
-- colliding or triggering anything.
function Player.canBeAt(wx, wz)
  return Player._tryMoveTo(wx, wz, true) == "SUCCESS"
end

-- Tries to move to the given position if possible.
-- If we successfully move to the position, returns "SUCCESS".
-- If we hit an entity or tile and triggered, returns "TRIGGERED".
-- If we can't move, returns "FAIL".
--
-- If you want just to check if the position is clear, you can pass
-- dryRun=true, in which case it will not actually move the player or
-- trigger collisions, it will just check and return what WOULD have
-- happened.
function Player._tryMoveTo(wx, wz, dryRun)
  -- Check for area bounds.
  if not Area.isWorldPosInBounds(wx, wz) then
    -- Out of bounds, can't be here.
    return "FAIL"
  end

  -- Check for collision against solid tiles in the area.
  -- Note that we allow the player to wander "off" the map, because that's
  -- how we detect we need to do a transition to a new area.
  local isClear, blockingTileMx, blockingTileMy = Area.checkWorldCircle(wx, wz, Player.COLLISION_RADIUS, {allowOob = true})
  if not isClear then
    -- Before failing, check if we collided with a tile that has a trigger.
    if not dryRun and blockingTileMx and blockingTileMy then
      -- Get the tile type from the blocking tile coordinates
      local tile = Area.tiles[blockingTileMx .. "," .. blockingTileMy]
      if tile then
        -- Try to handle tile collision trigger
        if Triggers.handleTileCollision(tile, blockingTileMx, blockingTileMy) then
          return "TRIGGERED"
        end
      end
    end
    return "FAIL"
  end

  -- Check for collision against solid entities in the area.
  local e = Entities.getEntInCircle(wx, wz, Player.COLLISION_RADIUS, ER_SOLID)
  if e then
    -- If dryRun, just say this WOULD have triggered an entity.
    if dryRun then return "TRIGGERED" end
    -- Collided with entity.
    Triggers.handleEntCollision(e)
    -- If the entity has ER_HURTS, then start the hurt state.
    if (e.recipe.flags & ER_HURTS) ~= 0 then
      Player._startHurt()
    end
    return "TRIGGERED"
  end

  -- Check for collision against trigger entities in the area.
  local e = Entities.getEntInCircle(wx, wz, Player.COLLISION_RADIUS, ER_TRIGGER)
  if e then
    -- If dryRun, just say this WOULD have triggered an entity.
    if dryRun then return "TRIGGERED" end
    -- Collided with entity.
    Triggers.handleEntCollision(e)
    -- Fall through to move player (triggering a non-solid entity
    -- doesn't cause the player to stop moving).
  end

  -- Move to the new position (unless this is a dry run).
  if not dryRun then Player.x, Player.z = wx, wz end

  return "SUCCESS"
end

function Player._updateHurt()
  if Player.hurtC then
    Player.hurtC = Player.hurtC + 1
    if Player.hurtC >= Player.HURT_DURATION then
      -- End of hurt sequence.
      Player.hurtC = nil
    else
      -- Nothing else to do while in the hurt state.
      return
    end
  end
  -- Check if there's an entity tagged as ER_HURTS intersecting with
  -- the player, using Entities.getEntInCircle. If there is, then
  -- start the hurt sequence.
  local hurtingEnt = Entities.getEntInCircle(
    Player.x, Player.z, Player.COLLISION_RADIUS, ER_HURTS)
  if hurtingEnt then
    Player._startHurt(hurtingEnt)
  end
end

-- Start the hurt sequence.
-- hurtingEnt (optional): the entity that caused the damage, if any
function Player._startHurt(hurtingEnt)
  if Player.hurtC then return end  -- Already hurt
  Player.hurtC = 0
  -- Reduce hitpoints when hurt
  Player.hp = Player.hp - 1
  -- Update hearts display
  HeartsBar.updateIfNeeded()
  -- Invert the player's velocity when hurt
  Player.vx = -Player.vx
  Player.vz = -Player.vz
  -- If that's not enough velocity, apply a small impulse away from the
  -- hurting entity.
  if hurtingEnt and Player.vx * Player.vx + Player.vz * Player.vz < 0.01 then
    -- Unit vector from entity to player.
    local dx, dz = Utils.normalize(hurtingEnt.x - Player.x, hurtingEnt.z - Player.z)
    Player.vx, Player.vz = -dx, -dz
  end

  -- Check if player died
  Player._checkDeath()
end

-- Check if the player has died and handle death
function Player._checkDeath()
  if Player.hp <= 0 then
    -- Show puff particle effect at the player's location
    -- (note that Player.update will take care of hiding the player Thing)
    Player.thing:particles("puff")
    -- Set main state to dead. This will effectively "pause" the game
    -- and allow the user to appreciate the circumstances of their demise.
    Main.goToState(MS_DEAD)
  end
end

function Player._updateStinkyDamage()
  -- Don't process stinky damage if player is already hurt, dead, or in effort state
  if Player.hurtC or Player.hp <= 0 or Player.effortCD > 0 then
    Player.stinkyStartTime = nil  -- Reset stinky timer
    return
  end
  
  -- Check if player is standing on a stinky tile
  if not Player._isOnStinkyTile() then
    Player.stinkyStartTime = nil  -- Reset stinky timer when leaving stinky tiles
    return
  end

  -- If the player has an active perfume effect, they are immune to stinky damage
  if Player.perfume > 0 then
    -- Ensure stinky countdown doesn't run while immune
    Player.stinkyStartTime = nil
    return
  end
  
  local currentTime = unixTime()
  
  -- If we just entered a stinky tile, start the countdown
  if not Player.stinkyStartTime then
    Player.stinkyStartTime = currentTime
    return
  end
  
  -- Calculate time since entering stinky tile
  local timeOnStinky = currentTime - Player.stinkyStartTime
  
  -- Check if enough time has passed to take damage
  if timeOnStinky >= Player.STINKY_DAMAGE_INTERVAL then
    -- Deal damage by starting the hurt sequence (no hurting entity)
    Player._startHurt()
    -- Reset the timer for next damage cycle
    Player.stinkyStartTime = currentTime
  end
end

-- Check if the player is currently standing on a tile with the specified flag
function Player._isOnTileWithFlag(flag)
  -- Get the tile coordinates for the player's current position
  local mx, my = Area.tileCoordsForWorldPos(Player.x, Player.z)
  
  -- Get the tile at the player's position
  local tile = Area.tiles[mx .. "," .. my]
  if not tile then
    return false  -- No tile data available
  end
  
  -- Get the recipe for this tile type
  local recipe = Area.recipes[tile]
  if not recipe then
    return false  -- No recipe available
  end
  
  -- Check if the tile has the specified flag
  return (recipe.flags or 0) & flag ~= 0
end

-- Check if the player is currently standing on a tile with the TF_STINKY flag
function Player._isOnStinkyTile()
  return Player._isOnTileWithFlag(TF_STINKY)
end

-- Check if the player is currently standing on a tile with the TF_SLIPPERY flag
function Player._isOnSlipperyTile()
  return Player._isOnTileWithFlag(TF_SLIPPERY)
end

function Player._updateTint()
  local newTint, newGlow
  if Player.hurtC then
    -- Player is hurt, set a red tint and glow.
    newTint = (Player.hurtC & 2 == 0) and "#ff0000" or "#880000"
    newGlow = 0.5
  elseif Player.stinkyStartTime then
    -- Player is on stinky tile, apply progressive green tint
    local timeOnStinky = unixTime() - Player.stinkyStartTime
    local progress = timeOnStinky / Player.STINKY_DAMAGE_INTERVAL
    progress = math.min(progress, 1.0)  -- Clamp to 1.0
    
    -- Calculate which step we're on (0 to STINKY_TINT_STEPS-1)
    local step = math.floor(progress * Player.STINKY_TINT_STEPS)
    step = math.min(step, Player.STINKY_TINT_STEPS - 1)
    
    -- Calculate green intensity: starts at 0xdd (221) and goes down to 0x00 (0)
    -- Red and blue components decrease as we approach damage
    local intensity = 221 - math.floor((step * 221) / (Player.STINKY_TINT_STEPS - 1))
    newTint = string.format("#%02xff%02x", intensity, intensity)
    newGlow = 0
  else
    -- Normal tint and no glow.
    newTint = "#ffffff"
    newGlow = 0
  end
  -- Set the tint if it has changed.
  if Player.lastTint ~= newTint then
    Player.torsoThing:setTint(newTint)
    Player.legsThing:setTint(newTint)
    Player.torsoThing:setGlow(newGlow)
    Player.legsThing:setGlow(newGlow)
    Player.lastTint = newTint
  end
end

-- Check if the player has at least one of the given item type
function Player.hasItem(itemType)
  return (Player.inventory[itemType] or 0) > 0
end

-- Add items to player inventory, enforcing max limit
function Player.addItem(itemType, count)
  count = count or 1
  if itemType < 1 or itemType > IT_MAX then
    return
  end
  count = count or 1
  local currentCount = Player.inventory[itemType] or 0
  local newCount = math.min(currentCount + count, Player.MAX_ITEMS_PER_TYPE)
  Player.inventory[itemType] = newCount
  
  -- Play pickup sound effect if items were actually added
  if newCount > currentCount then
    Sfx.play("PICKUP")

    Triggers.handleGlobalTrigger("IADD " .. itemType)
  end
end

-- Remove items from player inventory, returns true if successful
function Player.removeItem(itemType, count)
  count = count or 1
  if itemType < 1 or itemType > IT_MAX then
    return false
  end
  count = count or 1
  local currentCount = Player.inventory[itemType] or 0
  if currentCount < count then
    return false
  end
  Player.inventory[itemType] = currentCount - count
  
  -- If we removed the last of the equipped item, unequip it
  if Player.equipped == itemType and Player.inventory[itemType] == 0 then
    Player.equipped = nil
  end
  
  Triggers.handleGlobalTrigger("IREMOVE " .. itemType)
  return true
end

-- Get the count of a specific item type
function Player.getItemCount(itemType)
  if itemType < 1 or itemType > IT_MAX then
    return 0
  end
  return Player.inventory[itemType] or 0
end

-- Check if player has enough gold
function Player.hasGold(amount)
  return Player.gold >= amount
end

-- Remove gold from player, returns true if successful
function Player.removeGold(amount)
  if Player.gold < amount then
    return false
  end
  Player.gold = Player.gold - amount
  return true
end

-- Add gold to player, enforcing max limit
function Player.addGold(amount)
  Player.gold = math.min(Player.gold + amount, Player.GOLD_MAX)
end

-- Get the quality level of a specific item type
function Player.getItemQuality(itemType)
  if itemType < 1 or itemType > IT_MAX then
    return 0
  end
  return Player.itemQuality[itemType] or 0
end

-- Set the quality level of a specific item type
function Player.setItemQuality(itemType, quality)
  if itemType < 1 or itemType > IT_MAX then
    return false
  end
  Player.itemQuality[itemType] = math.max(0, math.min(3, math.floor(quality)))
  return true
end

-- Equip an item if the player has at least one in inventory
function Player.equipItem(itemType)
  if not Player.hasItem(itemType) then
    return false
  end
  Player.equipped = itemType
  return true
end

function Player.healFully()
  Player.hp = Player.hpMax
  HeartsBar.updateIfNeeded()
end

function Player.lightTorch()
  Player.torch = Player.TORCH_MAX
  Sfx.play("TORCH")
  -- Particle effect must wait because it takes a frame for the torch to
  -- be moved to the right position.
  wait(0.1,function()
    Player.torchThing:particles("puff",{color="#ffdd00"})
  end)
end

function Player.handleAreaChange()
  Player.torch = max(Player.torch - 1, 0)
  -- Decrease perfume duration on area switches
  if Player.perfume > 0 then
    Player.perfume = max(Player.perfume - 1, 0)
  end
end

function Player.applyPerfume()
  Player.perfume = Player.PERFUME_MAX
  Sfx.play("HEAL")
  -- show a small particle to indicate application
  Player.thing:particles("puff", {color="#cc88ff"})
end

-- Start an effort state that lasts for the specified number of frames
-- During effort state, player has no velocity and doesn't respond to controls
function Player.startEffort(numFrames)
  Player.effortCD = numFrames or 1
  -- Immediately stop all movement when starting effort
  Player.vx, Player.vz = 0, 0
end