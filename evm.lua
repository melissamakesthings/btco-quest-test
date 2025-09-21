-- ENTITY VIRTUAL MACHINE (EVM)

-- Instructions:
-- ANIM
--   f: frame number to set; OR:
--   fps, s, e: frame per second, start frame, end frame for animation.
-- MOVE
--   n: number of frames during which to move forward.
--   This will use the entity's speed and yaw to determine the movement.

Evm = {}

-- Updates the entity using the virtual machine.
function Evm.update(ent)
  -- Initialize VM state.
  ent.vmState = ent.vmState or {
    -- program counter
    pc = 1,
    -- the operation result from the last instruction,
    -- for use in conditional jumps and the like. This MUST BE A NUMBER.
    result = 0
  }
  local vms = ent.vmState
  local program = ent.recipe.program
  if not program then return end -- no program to run
  if not vms then error("Entity has no VM state") end

  local mustYield = false
  while not mustYield do
    -- Get the next instruction.
    local instr = program[vms.pc] or ""
    local handler = Evm.OPCODE_HANDLERS[instr.v]
    if not handler then
      error("Unknown opcode: " .. (instr.v or "(nil)") .. " at PC: " .. vms.pc)
    end
    -- Advance the program counter, looping back to 1 if it exceeds the length.
    local oldPc = vms.pc
    vms.pc = vms.pc + 1
    if vms.pc > #program then vms.pc = 1 end
    -- Execute the instruction and see what it returns.
    local result = handler(ent, vms, instr)
    if result == "YIELD" then
      mustYield = true
    elseif result == "REPEAT" then
      -- Yield but repeat the current instruction next time
      mustYield = true
      vms.pc = oldPc
    end
  end
end

function Evm._execANIM(ent, vms, instr)
  if instr.f then
    ent.thing:setFrame(instr.f)
  elseif instr.fps then
    ent.thing:setAnimation("loop", instr.fps, instr.s or 1, instr.e or -1)
  end
end

function Evm._execMOVE(ent, vms, instr)
  if not vms.moveState then
    -- Start moving
    vms.moveState = { n = instr.n or 1}
    vms.result = 0  -- we'll set this to 1 if we move successfully
    return "REPEAT"
  end
  -- Continue moving.
  vms.moveState.n = vms.moveState.n - 1
  local dx, dz = Utils.yawToXZ(ent.yaw, ent.recipe.speed or 1)
  local targetX, targetZ = ent.x + dx, ent.z + dz
  if Entities.canBeAt(ent, targetX, targetZ) then
    -- Move the entity.
    ent.x, ent.z = targetX, targetZ
  else
    -- Finished moving because we hit something.
    vms.result = 0  -- means "we hit something"
    vms.moveState = nil
    return "YIELD"
  end
  if vms.moveState.n <= 0 then
    -- Finished moving without hitting anything.
    vms.result = 1  -- means "we moved successfully"
    vms.moveState = nil
    return "YIELD"
  end
  return "REPEAT"  -- Continue moving
end

function Evm._execWAIT(ent, vms, instr)
  if not vms.waitState then
    -- Start waiting
    vms.waitState = { n = instr.n or 1 }
    return "REPEAT"
  end
  -- Continue waiting.
  vms.waitState.n = vms.waitState.n - 1
  if vms.waitState.n <= 0 then
    -- Finished waiting.
    vms.waitState = nil
    return "YIELD"
  end
  return "REPEAT"  -- Continue waiting
end

function Evm._execTURN(ent, vms, instr)
  -- Note: this is an immediate turn, not a gradual turn, because we rely
  -- on the automatic smoothing in the Player.update() function to make
  -- the turn seem gradual.
  ent.targetYaw =
    instr.mode == "FREE" and Evm._getRandomFreeYaw() or
    instr.mode == "AIM" and Evm._getYawToAimAtPlayer(ent) or
    instr.mode == "ANGLE" and (ent.targetYaw + (instr.angle or 0)) or 0
end

function Evm._getRandomFreeYaw()
  return random(4) * 90
end

function Evm._getYawToAimAtPlayer(ent)
  -- Assuming Player.x and Player.z are the player's position.
  local dx = Player.x - ent.x
  local dz = Player.z - ent.z
  return Utils.rad2Deg(Utils.atan2(dx, dz))  -- Convert to degrees
end

function Evm._execJMP(ent, vms, instr)
  if not instr.label then
    error("JMP instruction missing 'label' field")
  end
  -- Find the label's instruction index.
  for i, v in ipairs(ent.recipe.program) do
    if v.v == "LABEL" and v.name == instr.label then
      vms.pc = i
      return
    end
  end
  error("Unknown label: " .. (instr.label or "(nil)"))
end

function Evm._execSAY(ent, vms, instr)
  ent.thing:say(instr.text or "???")
end

function Evm._execFIRE(ent, vms, instr)
  local projectileType = instr.what
  if not projectileType then
    error("FIRE instruction missing 'what' field")
  end
  
  local offset = instr.offset or 0
  local speed = instr.speed
  
  -- Calculate position to spawn the projectile (ahead of the firing entity)
  local offsetX, offsetZ = Utils.yawToXZ(ent.yaw, offset)
  local spawnX = ent.x + offsetX
  local spawnZ = ent.z + offsetZ
  
  -- Create the projectile entity
  local projectile = Entities.create(projectileType, spawnX, spawnZ, ent.yaw)
  if not projectile then return end
  -- Set the projectile's velocity based on its yaw and speed
  local projectileSpeed = speed or projectile.recipe.speed or 1
  local vx, vz = Utils.yawToXZ(projectile.yaw, projectileSpeed)
  projectile.vx = vx
  projectile.vz = vz
  
  -- If this isn't set by the recipe, force a TTL.
  projectile.ttl = projectile.ttl or 120

  -- volume is proportional to how close the entity is to the player
  local dist = math.sqrt((ent.x - Player.x)^2 + (ent.z - Player.z)^2)
  local volume = math.max(0.15, 1 - (dist * 0.004))
  Sfx.play("FIRE", volume)
end

Evm.OPCODE_HANDLERS = {
  LABEL = function() end,
  ANIM = Evm._execANIM,
  MOVE = Evm._execMOVE,
  TURN = Evm._execTURN,
  WAIT = Evm._execWAIT,
  SAY = Evm._execSAY,
  JMP = Evm._execJMP,
  FIRE = Evm._execFIRE,
}
