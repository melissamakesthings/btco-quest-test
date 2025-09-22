Entities = {
  -- Friction applied to velocity per frame
  FRICTION = 0.2,
  
  -- Duration of black tint effect when entity takes damage (in frames)
  DAMAGE_TINT_DURATION = 4,

  -- Entities currently in the area.
  -- This is a dictionary where the key is the entity ID and the
  -- value is an Entity, each of which having the following fields:
  --   eid: unique entity ID (string)
  --   etype: entity type (ET_* constants)
  --   recipe: reference to the recipe for this entity type.
  --   thing: the Thing that represents this entity in the world. Note that
  --     while the entity is alive, the Thing isn't in the thingPool, so when
  --     deleting the entity, it should be returned to the pool.
  --   x, y, z: world position
  --   vx, vz: if present, the velocity in the X and Z directions.
  --     This is given in units per frame, so this is added to the entity's
  --     position every frame.
  --   yaw: yaw rotation in degrees (current)
  --   targetYaw: yaw rotation in degrees (desired)
  --   age: age in ticks
  --   ttl: if present, once the entity reaches this age, it will be removed
  --   vmState: VM state (see evm.lua)
  ents = {},

  -- Thing pool per entity group name.
  -- So thingPool["EntGroupA"], for example, will contain all Things for
  -- entities of group "EntGroupA".
  -- All things in the pool are currently unused and invisible, ready to be
  -- used to represent an entity when needed.
  thingPool = {},

  -- Next dynamic entity ID number to use for dynamically created entities.
  nextDynamicEid = 1,

  -- List of EIDs of enemies recently killed, so they don't come back when entering
  -- a new area. This list is kept only in RAM so if the game is saved and
  -- reloaded, it will be lost and all enemies will respawn.
  recentlyKilledEids = {},
  MAX_RECENTLY_KILLED = 32,  -- Max number of recently killed enemies to remember
}

-- Entity recipe flags.
ER_HURTS = 1 << 0
ER_VULNERABLE = 1 << 1
ER_SOLID = 1 << 2  -- Entity is solid and can't be walked through.
ER_NO_FRICTION = 1 << 3  -- Entity doesn't apply friction to its velocity.
ER_FRAGILE = 1 << 4  -- Entity is removed on collision with anything solid
ER_TRIGGER = 1 << 5  -- Entity issues a trigger when collided with,
                     -- despite not being solid (ER_SOLID entities always
                     -- trigger on collision).

-- Recipes for creating entities based on their type.
-- Recipe fields are:
--   group (string, required): Thing pool group name for this entity type
--   flags (number, optional): Bitwise OR of ER_* flags for entity behavior
--   frame (number, optional): Static sprite frame to display (mutually exclusive with anim)
--   anim (table, optional): Animation spec {mode, fps, startFrame, endFrame} (mutually exclusive with frame)
--   tint (string, optional): Hex color tint to apply (default "#ffffff" = no tint)
--   glow (number, optional): Glow intensity (0 = no glow)
--   radius (number, optional): Collision radius in world units
--   y (number, optional): Y-offset from ground level
--   scale (number, optional): Visual scale multiplier (1.0 = normal size)
--   yawOverride (number, optional): Fixed rotation angle in degrees
--   speed (number, optional): Movement speed in world units per frame
--   hp (number, optional): Health points (if not specified, vulnerable entities default to 1)
--   mass (number, optional): Mass for momentum calculations when taking damage (default: 1)
--   ttl (number, optional): Time-to-live in frames before automatic removal
--   spin (number, optional): Rotation speed in degrees per frame

--   program (table, optional): EVM program for AI behavior (see evm.lua)
--   lootDrop (table, optional): Array of entity types that may drop on death (nil = no drop)
--   consumedType (number, optional): If set, if this entity is consumed, it will change to this type
Entities.recipes = {
  [ET_ANT] = {
    group = "EntGroupA",
    flags = ER_HURTS | ER_VULNERABLE,
    tint = "#ffff00",
    frame = 1,
    radius = 3.5,
    y = 0,
    scale = 1.2,
    speed = 0.2,
    hp = 2,
    program = {
      {v="LABEL", name="A"},
      {v="ANIM", f=1}, -- "standing still" frame
      {v="TURN", mode="FREE"}, -- turn to a free direction
      {v="WAIT", n=4},
      {v="ANIM", fps=4, s=1, e=2}, -- walk anim
      {v="MOVE", n=90}, -- move forward
      {v="LABEL", name="HURT"}, -- jump here when hurt
      {v="TURN", mode="AIM"}, -- turn to aim at player
      {v="ANIM", f=1}, -- "standing still" frame
      {v="WAIT", n=4},
      {v="ANIM", fps=4, s=1, e=2}, -- walk anim
      {v="MOVE", n=90}, -- move towards player
    },
    lootDrop = { ET_GOLD_PIECE, nil } -- 1/2 chance of a gold piece
  },
  [ET_BAT] = {
    group = "EntGroupA",
    flags = ER_HURTS | ER_VULNERABLE,
    tint = "#00f0ff",
    frame = 4,
    radius = 3.5,
    y = 0,
    scale = 1.2,
    speed = 1.0,
    hp = 4,
    program = {
      {v="ANIM", f=4 }, -- "standing still" frame
      {v="TURN", mode="AIM"}, -- always turn to aim at player
      {v="WAIT", n=4},
      {v="ANIM", fps=4, s=4, e=5}, -- walk anim
      {v="MOVE", n=40}, -- move towards player
    },
    lootDrop = { ET_GOLD_PIECE } -- always drops a gold piece
  },
  [ET_FIRE_ANT] = {
    group = "EntGroupA",
    flags = ER_HURTS | ER_VULNERABLE,
    tint = "#ff8000",
    frame = 1,
    radius = 3.5,
    y = 0,
    scale = 1.2,
    speed = 0.7,
    hp = 3,
    program = {
      {v="LABEL", name="A"},
      {v="ANIM", f=1}, -- "standing still" frame
      {v="TURN", mode="FREE"}, -- turn to a free direction
      {v="WAIT", n=4},
      {v="ANIM", fps=4, s=1, e=2}, -- walk anim
      {v="MOVE", n=40}, -- move forward
      {v="LABEL", name="HURT"}, -- jump here when hurt
      {v="ANIM", f=1}, -- "standing still" frame
      {v="TURN", mode="AIM"}, -- turn to aim at player
      {v="WAIT", n=30},
      {v="ANIM", f=3}, -- aim frame
      {v="WAIT", n=4},
      {v="FIRE", what=ET_FIREBALL, offset=5},
      {v="ANIM", f=1}, -- "standing still" frame
      {v="WAIT", n=4},
    },
    lootDrop = { ET_GOLD_PILE }
  },
  [ET_SCORPION] = {
    group = "EntGroupA",
    flags = ER_HURTS | ER_VULNERABLE,
    tint = "#ffb040",
    frame = 6,
    radius = 4,
    y = 0,
    scale = 1.2,
    speed = 2.0,
    hp = 6,
    program = {
      {v="ANIM", f=6 }, -- "standing still" frame
      {v="TURN", mode="AIM"}, -- always turn to aim at player
      {v="WAIT", n=4},
      {v="ANIM", fps=5, s=6, e=7}, -- walk anim
      {v="MOVE", n=20}, -- move towards player
    },
    lootDrop = { ET_GOLD_PILE }
  },
  [ET_FINAL_BOSS] = {
    group = "EntGroupD",
    flags = ER_HURTS | ER_VULNERABLE,
    frame = 2,
    radius = 6,
    y = 0,
    scale = 1.2,
    speed = 1,
    glow = 1.5,
    hp = 30,
    program = {
      {v="WAIT", n=10}, -- initial wait

      {v="LABEL", name="LOOP"},

      {v="ANIM", f=2}, -- "standing still" frame

      {v="LABEL", name="HURT"}, -- jump here when hurt
      {v="TURN", mode="AIM"}, -- turn to aim at player
      {v="WAIT", n=30},
      {v="FIRE", what=ET_FIREBALL_FAST, offset=7},

      {v="TURN", mode="AIM"}, -- turn to aim at player
      {v="WAIT", n=5},
      {v="FIRE", what=ET_FIREBALL_FAST, offset=7},

      {v="TURN", mode="AIM"}, -- turn to aim at player
      {v="WAIT", n=5},
      {v="FIRE", what=ET_FIREBALL_FAST, offset=7},

      {v="TURN", mode="AIM"}, -- turn to aim at player
      {v="WAIT", n=5},
      {v="FIRE", what=ET_FIREBALL_FAST, offset=7},

      {v="TURN", mode="AIM"}, -- turn to aim at player
      {v="WAIT", n=5},
      {v="FIRE", what=ET_FIREBALL_FAST, offset=7},

      {v="TURN", mode="AIM"}, -- turn to aim at player
      {v="WAIT", n=5},
      {v="FIRE", what=ET_FIREBALL_FAST, offset=7},

      {v="TURN", mode="AIM"}, -- turn to aim at player
      {v="WAIT", n=5},
      {v="FIRE", what=ET_FIREBALL_FAST, offset=7},

      {v="TURN", mode="AIM"}, -- turn to aim at player
      {v="WAIT", n=5},
      {v="FIRE", what=ET_FIREBALL_FAST, offset=7},

      {v="TURN", mode="AIM"}, -- turn to aim at player
      {v="WAIT", n=5},
      {v="FIRE", what=ET_FIREBALL_FAST, offset=7},

      {v="ANIM", f=2}, -- "standing still" frame
      {v="TURN", mode="AIM"}, -- turn to aim at player
      {v="WAIT", n=4},
      {v="ANIM", fps=4, s=4, e=5}, -- walk anim
      {v="MOVE", n=60}, -- move forward

      {v="TURN", mode="AIM"}, -- turn to aim at player
      {v="WAIT", n=4},
      {v="ANIM", fps=4, s=4, e=5}, -- walk anim
      {v="MOVE", n=60}, -- move forward

      {v="JMP", label="LOOP"},
    },
  },
  [ET_FIREBALL] = {
    group = "EntGroupB",
    flags = ER_HURTS | ER_NO_FRICTION | ER_FRAGILE,
    tint = "#ffff00",
    frame = 1,
    glow = 1,
    radius = 3,
    y = 2,
    speed = 3,
    ttl = 90,
    spin = 15,  -- degrees per frame
  },
  [ET_FIREBALL_FAST] = {
    group = "EntGroupB",
    flags = ER_HURTS | ER_NO_FRICTION | ER_FRAGILE,
    tint = "#00ff00",
    frame = 1,
    glow = 2,
    radius = 4,
    y = 2,
    speed = 4,
    scale = 1.5,
    ttl = 90,
    spin = 30,  -- degrees per frame
  },
  [ET_NPC_1] = {   -- oppidanus
    group = "EntGroupB",
    flags = ER_SOLID,
    frame = 2,
    radius = 5,
    yawOverride = 180,
  },
  [ET_NPC_2] = {   -- propola
    group = "EntGroupB",
    flags = ER_SOLID,
    frame = 7,
    radius = 5,
    yawOverride = 180,
  },
  [ET_NPC_3] = {  -- faber ferrarius
    group = "EntGroupB",
    flags = ER_SOLID,
    frame = 8,
    radius = 5,
    yawOverride = 180,
  },
  [ET_NPC_4] = {   -- mercator potionum
    group = "EntGroupB",
    flags = ER_SOLID,
    frame = 9,
    radius = 5,
    yawOverride = 180,
  },
  [ET_NPC_5] = {   -- unguentarius
    group = "EntGroupB",
    flags = ER_SOLID,
    frame = 10,
    radius = 5,
    yawOverride = 180,
  },
  [ET_NPC_6] = {   -- aedilis
    group = "EntGroupB",
    flags = ER_SOLID,
    frame = 11,
    radius = 5,
    yawOverride = 180,
  },
  [ET_SIGN] = {
    group = "EntGroupB",
    flags = ER_SOLID,
    frame = 3,
    radius = 4,
  },
  [ET_SWORD] = {
    group = "EntGroupB",
    flags = ER_SOLID,
    frame = 4,
    radius = 4,
    yawOverride = 45,
  },
  [ET_FOUNTAIN] = {
    group = "EntGroupB",
    flags = ER_SOLID,
    anim = {"loop", 5, 5, 6},
    radius = 4,
  },
  [ET_FIREBUSH] = {
    group = "EntGroupB",
    flags = ER_SOLID,
    frame = 12,
    radius = 5,
    glow = 3,
  },
  [ET_LAVENDER] = {
    group = "EntGroupC",
    flags = ER_SOLID,
    frame = 9,
    radius = 5,
    glow = 1,
  },
  [ET_GOLD_PIECE] = {
    group = "EntGroupB",
    flags = ER_TRIGGER,
    frame = 13,
    radius = 3,
    glow = 0.5,
  },
  [ET_GOLD_PILE] = {
    group = "EntGroupC",
    flags = ER_TRIGGER,
    frame = 12,
    radius = 3,
    glow = 0.5,
  },
  [ET_CHEST] = {
    group = "EntGroupB",
    flags = ER_SOLID,
    frame = 14,
    radius = 6,
    glow = 0.5,
    consumedType = ET_CHEST_OPEN, -- when consumed, changes to this type
  },
  [ET_CHEST_OPEN] = {
    group = "EntGroupB",
    flags = ER_SOLID,
    frame = 15,
    radius = 6,
    glow = 0,
  },
  [ET_DOOR] = {
    group = "EntGroupC",
    flags = ER_SOLID,
    frame = 1,
    radius = 4,
  },
  [ET_DOOR_OPEN] = {
    group = "EntGroupC",
    flags = 0,
    frame = 2,
    radius = 4,
  },
  [ET_DOOR_LOCKED] = {
    group = "EntGroupC",
    flags = ER_SOLID,
    frame = 3,
    radius = 4,
    consumedType = ET_DOOR_OPEN, -- when consumed, changes to this type
  },
  [ET_BARS] = {
    group = "EntGroupC",
    flags = ER_SOLID,
    frame = 4,
    radius = 4,
  },
  [ET_LEVER] = {
    group = "EntGroupC",
    flags = ER_SOLID,
    frame = 5,
    radius = 4,
    glow = 0.5,
    consumedType = ET_LEVER_PULLED,
  },
  [ET_LEVER_PULLED] = {
    group = "EntGroupC",
    flags = ER_SOLID,
    frame = 6,
    radius = 4,
  },
  [ET_WELL] = {
    group = "EntGroupB",
    flags = ER_SOLID,
    frame = 16,
    radius = 6,
    glow = 0.5,
    consumedType = ET_WELL_DRAINED, -- when consumed, changes to this type
  },
  [ET_WELL_DRAINED] = {
    group = "EntGroupB",
    flags = ER_SOLID,
    tint = "#404040",
    frame = 16,
    radius = 6,
    consumedType = ET_WELL_DRAINED, -- when consumed, changes to this type
  },
  [ET_NPC_ARCHITECT] = {
    group = "EntGroupD",
    flags = ER_SOLID,
    frame = 1,
    radius = 5,
    yawOverride = 180,
  },
  [ET_BOOK] = {
    group = "EntGroupC",
    flags = ER_SOLID,
    frame = 7,
    radius = 4,
    yawOverride = 45,
  },
  [ET_SHIP] = {
    group = "EntGroupC",
    flags = ER_SOLID,
    frame = 8,
    radius = 30,
    scale = 2,
    y = -8,
    bob = 1,
    yawOverride = 90,
  },
  [ET_GATE] = {
    group = "EntGroupC",
    flags = ER_SOLID,
    frame = 10,
    radius = 4,
    consumedType = ET_GATE_OPEN,
  },
  [ET_GATE_OPEN] = {
    group = "EntGroupC",
    flags = 0,
    frame = 11,
    radius = 4,
  },
  [ET_GEMINI] = {
    group = "EntGroupB",
    flags = ER_SOLID,
    frame = 11,
    radius = 5,
    yawOverride = 180,
  },  
}

function Entities.init()
  -- Initialize the pool
  local children = getThing("Entities"):getChildren()
  for _, thing in ipairs(children) do
    -- The group name is the first part of the Thing's name before the first space.
    local groupName = split(thing:getName(), " ")[1]
    if not groupName or groupName == "" then
      error("Entity thing '" .. thing:getName() .. "' must have a group name as its first part")
    end
    if not Entities.thingPool[groupName] then
      Entities.thingPool[groupName] = { thing }
    else
      table.insert(Entities.thingPool[groupName], thing)
    end
    -- Set the thing to be invisible by default.
    thing:setPosition(0, -100000, 0)
  end
end

-- Generates a deterministic EID for an entity based on area position
-- Format: XYxy where X=areaX, Y=areaY, x=mx, y=my (all in hex)
function Entities.generateMapEid(areaX, areaY, mx, my)
  -- Validate ranges
  if areaX < 0 or areaX > 15 then error("areaX out of range (0-15): " .. areaX) end
  if areaY < 0 or areaY > 15 then error("areaY out of range (0-15): " .. areaY) end
  if mx < 0 or mx > 15 then error("mx out of range (0-15): " .. mx) end
  if my < 0 or my > 11 then error("my out of range (0-11): " .. my) end
  return string.format("%X%X%X%X", areaX, areaY, mx, my)
end

-- Generates a dynamic EID for dynamically created entities
function Entities.generateDynamicEid()
  local eid = "DYNAMIC:" .. Entities.nextDynamicEid
  Entities.nextDynamicEid = Entities.nextDynamicEid + 1
  return eid
end

-- NOTE: this can return nil if the entity can't be created (e.g., no available
-- Things in the pool).
-- If mapPosition is provided, it should be a table with {areaX, areaY, mx, my}
-- to generate a deterministic EID. Otherwise, a dynamic EID will be used.
function Entities.create(etype, x, z, yaw, mapPosition)
  local recipe = Entities.recipes[etype]
  if not recipe then
    error("No recipe found for entity type: " .. etype)
  end

  -- Generate the entity ID first to check for consumption
  local eid
  if mapPosition then
    eid = Entities.generateMapEid(
      mapPosition.areaX, mapPosition.areaY,
      mapPosition.mx, mapPosition.my)
  else
    eid = Entities.generateDynamicEid()
  end
  
  -- Check if this entity has been consumed and shouldn't be created
  if Persister.isEntityConsumed(eid) then
    if recipe.consumedType then
      -- Spawn another type of entity to represent the consumed entity.
      etype = recipe.consumedType
      recipe = Entities.recipes[etype]
    else
      -- Don't spawn.
      return nil
    end
  end
  -- If this entity is in the recently killed list, don't create it
  if Entities.isRecentlyKilled(eid) then
    return nil
  end

  -- Get a thing from the pool for this entity's group.
  local thingPool = Entities.thingPool[recipe.group]
  if not thingPool or #thingPool == 0 then
    -- No available Things in the pool for this group.
    return nil
  end
  local thing = table.remove(thingPool)
  
  local ent = {
    eid = eid,
    etype = etype,
    recipe = recipe,
    thing = thing,
    x = x,
    y = recipe.y or 0,
    z = z,
    yaw = recipe.yawOverride or yaw or 0,
    targetYaw = recipe.yawOverride or yaw or 0,
    age = 0,
    ttl = recipe.ttl, -- (optional, can be nil)
  }

  -- Initialize HP if the entity has it in the recipe, or default to 1 for vulnerable entities
  if recipe.hp then
    ent.hp = recipe.hp
  elseif recipe.flags and (recipe.flags & ER_VULNERABLE) == ER_VULNERABLE then
    ent.hp = 1
  end

  -- Initialize the Thing's position and rotation.
  thing:setPosition(ent.x, ent.y, ent.z)
  thing:setRotation(0, ent.yaw, 0)
  -- Initialize the Thing's frame or animation based on the recipe.
  if recipe.anim then
    thing:setAnimation(recipe.anim[1], recipe.anim[2], recipe.anim[3], recipe.anim[4])
  else
    thing:setFrame(recipe.frame or 1)
  end
  -- Apply tint from recipe if specified
  thing:setTint(recipe.tint or "#ffffff")
  -- Set the glow if specified
  thing:setGlow(recipe.glow or 0)
  -- Set the scale if specified
  thing:setScale(recipe.scale or 1)
  -- Add the entity to the list.
  Entities.ents[eid] = ent

  return ent
end

-- Deletes all entities of the given type.
function Entities.deleteAllOfType(etype)
  local entsToDelete = {}
  for eid, ent in pairs(Entities.ents) do
    if ent.etype == etype then
      table.insert(entsToDelete, ent)
    end
  end
  for _, ent in ipairs(entsToDelete) do Entities._delete(ent) end
end

-- Checks if a given EID exists (is alive).
function Entities.exists(eid)
  return Entities.ents[eid] ~= nil
end

-- Consumes all entities of the given type.
function Entities.consumeAllOfType(etype)
  local entsToConsume = {}
  -- Note: consuming an entity removes it from the list, so we need to be
  -- careful about iteration - that's why we build a separate list.
  for eid, ent in pairs(Entities.ents) do
    if ent.etype == etype then
      table.insert(entsToConsume, ent)
    end
  end
  for _, ent in ipairs(entsToConsume) do Entities.consume(ent) end
end

-- Returns the first entity of the given type (or nil if none).
-- Skips entities that are dead.
function Entities.getEntByType(etype)
  for _, ent in pairs(Entities.ents) do
    if not ent.dead and ent.etype == etype then
      return ent
    end
  end
  return nil
end

-- Returns all entities of the given type (empty list if none).
-- Skips entities that are dead.
function Entities.getEntsByType(etype)
  local result = {}
  for _, ent in pairs(Entities.ents) do
    if not ent.dead and ent.etype == etype then
      table.insert(result, ent)
    end
  end
  return result
end

function Entities._delete(ent)
  if not ent then
    -- Not an error (already deleted or never existed).
    return
  end

  -- Return the Thing to the pool.
  local thingPool = Entities.thingPool[ent.recipe.group]
  if not thingPool then
    error("No thing pool found for group: " .. ent.recipe.group)
  end
  table.insert(thingPool, ent.thing)

  -- Make it invisible
  ent.thing:setPosition(0, -100000, 0)

  -- Remove the entity from the list.
  Entities.ents[ent.eid] = nil

  -- Markers may need to update in response to an entity being deleted.
  Markers.checkDeletedEnts()
end

-- Deletes all entities.
function Entities.clear()
  local ents = {}
  for eid, ent in pairs(Entities.ents) do table.insert(ents, ent) end
  while #ents > 0 do Entities._delete(table.remove(ents)) end
  -- Reset the dynamic EID counter when clearing all entities
  Entities.nextDynamicEid = 1
end

Entities.update_entsToDelete = {}  -- temp array
function Entities.update()
  local delenda = Entities.update_entsToDelete
  -- Update each entity.
  for eid, ent in pairs(Entities.ents) do
    Entities._updateSingleEnt(ent)
    if ent.dead then table.insert(delenda, ent) end
  end
  -- Remove entities marked for deletion.
  while #delenda > 0 do Entities._delete(table.remove(delenda)) end
end

-- Applies friction to a speed component, returning the new speed
function Entities._applyFrictionToSpeed(speed)
  speed = speed or 0
  if math.abs(speed) <= Entities.FRICTION then return 0 end
  return speed - (speed > 0 and Entities.FRICTION or -Entities.FRICTION)
end

-- Applies velocity to an entity, handling collisions
function Entities._applyVelocity(ent)
  if not (ent.vx or ent.vz) then
    return
  end
  
  local newX = ent.x + (ent.vx or 0)
  local newZ = ent.z + (ent.vz or 0)
  
  -- Check if the entity can move to the new position
  if Entities.canBeAt(ent, newX, newZ) then
    -- Move the entity
    ent.x = newX
    ent.z = newZ
  else
    -- Hit something solid
    local flags = ent.recipe.flags or 0
    if (flags & ER_FRAGILE) ~= 0 then
      -- Fragile entity hits something, mark for deletion
      Entities._markEntityDead(ent)
      return
    else
      -- Non-fragile entity, just stop
      ent.vx = 0
      ent.vz = 0
    end
  end

  -- Apply friction to velocity components unless entity has ER_NO_FRICTION flag
  local flags = ent.recipe.flags or 0
  if (flags & ER_NO_FRICTION) == 0 then
    if ent.vx then ent.vx = Entities._applyFrictionToSpeed(ent.vx) end
    if ent.vz then ent.vz = Entities._applyFrictionToSpeed(ent.vz) end
  end
end

function Entities._updateSingleEnt(ent)
  ent.age = ent.age + 1
  -- If it has a TTL and has reached it, mark it for deletion.
  if ent.ttl and ent.age >= ent.ttl then
    Entities._markEntityDead(ent)
    return
  end
  
  -- Handle damage tint effect
  if ent.damageTintRemaining then
    ent.damageTintRemaining = ent.damageTintRemaining - 1
    if ent.damageTintRemaining <= 0 then
      -- Restore original tint and glow
      ent.thing:setTint(ent.originalTint or "#FFFFFF")
      local originalGlow = ent.recipe.glow or 0
      ent.thing:setGlow(originalGlow)
      ent.damageTintRemaining = nil
      ent.originalTint = nil
    end
  end
  
  -- Let the entity's virtual machine control it.
  if ent.recipe.program then Evm.update(ent) end

  -- Apply velocity if present
  Entities._applyVelocity(ent)

  -- Handle spinning if the entity has spin speed
  if ent.recipe.spin then
    ent.yaw = ent.yaw + ent.recipe.spin  -- Apply spin directly (degrees per frame)
    ent.targetYaw = ent.yaw  -- Keep target yaw in sync with actual yaw for spinning entities
  end

  -- Lerp current yaw towards the target yaw.
  ent.yaw = Utils.lerpAngle(ent.yaw, ent.targetYaw, 0.2)
  -- Optionally bob up and down if the recipe specifies a 'bob' amplitude.
  -- Baseline is recipe.y (falling back to ent.y). Default bob period is 60 frames,
  -- which can be overridden by recipe.bobPeriod (in frames).
  local displayY = ent.y
  local bobAmp = ent.recipe.bob
  if bobAmp and type(bobAmp) == "number" and bobAmp ~= 0 then
    local baseline = ent.recipe.y or ent.y or 0
    local period = ent.recipe.bobPeriod or 60
    local angle = (ent.age / period) * (2 * math.pi)
    displayY = baseline + math.sin(angle) * bobAmp
  end
  -- Update the Thing's position and rotation.
  ent.thing:setPosition(ent.x, displayY, ent.z)
  ent.thing:setRotation(0, ent.yaw, 0)
end

-- Checks if the entity can be at the given world coordinates, that is,
-- doesn't collide with anything solid and doesn't go out of bounds.
function Entities.canBeAt(ent, wx, wz)
  local radius = ent.recipe.radius or 1
  -- Check for collision against solid tiles in the area.
  -- Note that we also disallow occluded tiles, because we don't want
  -- enemies to hide behind walls as that's unfair to the player :-D
  local isClear = Area.checkWorldCircle(
    wx, wz, radius, {allowOob = false, disallowOccluded = true})
  if not isClear then
    -- Collides against a solid tile, or out of bounds.
    return false
  end
  -- Check if it collides against another entity.
  for _, otherEnt in pairs(Entities.ents) do
    -- Don't check against itself or dead entities.
    if otherEnt.eid ~= ent.eid and not otherEnt.dead then
      local dx = otherEnt.x - wx
      local dz = otherEnt.z - wz
      local distSq = dx * dx + dz * dz
      if distSq < (radius + (otherEnt.recipe.radius or 1))^2 then
        -- Collision detected.
        return false
      end
    end
  end
  -- TODO: collide against player? or let them take damage if the
  -- entity hits them?
  return true
end

-- If there are any entities in the given world circle (wx, wz, radius),
-- returns the first entity found, otherwise returns nil.
-- If rflags is provided, only entities with those recipe flags will be
-- considered.
function Entities.getEntInCircle(wx, wz, radius, rflags)
  rflags = rflags or 0
  for _, ent in pairs(Entities.ents) do
    if not ent.dead then  -- Skip dead entities
      local dx = ent.x - wx
      local dz = ent.z - wz
      local distSq = dx * dx + dz * dz
      if distSq < (radius + (ent.recipe.radius or 1))^2 then
        local myRFlags = ent.recipe.flags or 0
        if (myRFlags & rflags) == rflags then return ent end
      end
    end
  end
  return nil
end

-- Deals the given amount of damage to the given entity.
-- momX and momZ are optional momentum vectors to apply to the entity
-- as a result of the damage. The actual velocity of the entity will be
-- that divided by its mass (1 by default).
function Entities.dealDamage(ent, damage, momX, momZ)
  if not ent.hp then
    -- Entity has no HP, can't take damage
    return
  end
  
  -- Subtract damage from HP
  ent.hp = ent.hp - damage
  
  -- Apply momentum as velocity if provided
  if momX or momZ then
    local mass = ent.recipe.mass or 1
    ent.vx = (momX or 0) / mass
    ent.vz = (momZ or 0) / mass
  end
  
  -- Apply damage tint and glow effect
  if not ent.damageTintRemaining then
    -- Save the original tint if we're not already in a damage effect
    ent.originalTint = ent.thing:getTint()
  end
  ent.thing:setTint("#FF0000")  -- Red tint
  local originalGlow = ent.recipe.glow or 0
  ent.thing:setGlow(originalGlow + 1)  -- Add glow on top of original
  ent.damageTintRemaining = Entities.DAMAGE_TINT_DURATION
  
  -- Check if entity died
  if ent.hp <= 0 then
    Entities._markEntityDead(ent)
    ent.thing:particles("puff")
    Entities._maybeDropLoot(ent)  -- Handle loot drop if applicable
    Entities._addToRecentlyKilled(ent.eid)
  end
end

function Entities.isRecentlyKilled(eid)
  -- Check if the entity ID is in the recently killed list
  for _, killedEid in ipairs(Entities.recentlyKilledEids) do
    if killedEid == eid then
      return true
    end
  end
  return false
end

function Entities.markAsRecentlyKilled(ent)
  if not ent or not ent.eid then error("markAsRecentlyKilled: must pass entity") end
  Entities._addToRecentlyKilled(ent.eid)
end

function Entities._addToRecentlyKilled(eid)
  if Entities.isRecentlyKilled(eid) then return end
  insert(Entities.recentlyKilledEids, eid)
  if #Entities.recentlyKilledEids > Entities.MAX_RECENTLY_KILLED then
    table.remove(Entities.recentlyKilledEids, 1)
  end
end

-- Consumes an entity by marking it as consumed in the Persister,
-- setting it to dead, and optionally replacing it with its consumedType
-- if one is specified in the entity's recipe.
function Entities.consume(ent)
  if not ent then return end
  
  -- Mark the entity as consumed so it doesn't respawn
  Persister.consumeEntity(ent.eid)
  
  -- Mark for deletion
  Entities._markEntityDead(ent)
  
  -- If this entity has a "consumed" entity type (it changes to that instead
  -- of disappearing) then replace it now.
  if ent.recipe.consumedType then
    Entities.create(ent.recipe.consumedType, ent.x, ent.z)
  end
end

-- Helper function to handle entity death, including trigger calls
function Entities._markEntityDead(ent)
  if ent.dead then return end  -- Already dead, don't trigger again
  
  ent.dead = true
  
  -- Call the death trigger "EDEAD " .. etype and pass the entity
  local triggerName = "EDEAD " .. ent.etype
  local trigger = ALL_TRIGGERS[triggerName]
  if trigger then
    trigger(ent)
  end
end

function Entities._maybeDropLoot(ent)
  local dropSchedule = ent.recipe.lootDrop
  if not dropSchedule then return end

  -- Select one of the items in dropSchedule randomly. They
  -- are equi-probable, so we can just pick one based on a random index.
  local randomIndex = math.random(1, #dropSchedule)
  local entTypeToCreate = dropSchedule[randomIndex]
  if not entTypeToCreate then return end  -- Better luck next time!

  Entities.create(entTypeToCreate, ent.x, ent.z, 0)
end

