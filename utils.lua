Utils = {}

-- Lerps from a (in degrees) to b (in degrees) by t (0 to 1).
-- This takes the shortest path around the circle. This works even if angles aren't
-- normalized (i.e., they can be greater than 360 or less than 0).
function Utils.lerpAngle(a, b, t)
  -- Bring the difference into [-180, 180)
  local diff = ((b - a + 540) % 360) - 180     -- 540 = 360 + 180
  -- Linear interpolation along that signed difference
  local res  = a + diff * t
  -- Wrap result to [0, 360)
  return (res % 360 + 360) % 360
end

-- Classic atan2 function.
function Utils.atan2(y, x)
  if x > 0 then
    return math.atan(y / x)
  elseif x < 0 then
    if y >= 0 then
      return math.atan(y / x) + math.pi
    else
      return math.atan(y / x) - math.pi
    end
  elseif x == 0 then
    if y > 0 then
      return math.pi / 2
    elseif y < 0 then
      return -math.pi / 2
    else
      return 0 -- undefined, but we return 0
    end
  end
end

-- Converts a yaw angle (in degrees) to X and Z components.
-- yaw = 0 is north, meaning x = 0, z = 1
-- yaw = 90 is east, meaning x = 1, z = 0
-- yaw = 180 is south, meaning x = 0, z = -1
-- yaw = 270 is west, meaning x = -1, z = 0
-- If s is provided, it will scale the x and z components by s.
function Utils.yawToXZ(yaw, s)
  local rad = Utils.deg2Rad(yaw)
  return math.sin(rad) * (s or 1), math.cos(rad) * (s or 1)
end

-- Converts radians to degrees.
function Utils.rad2Deg(rad)
  return rad * (180 / math.pi)
end

-- Converts degrees to radians.
function Utils.deg2Rad(deg)
  return deg * (math.pi / 180)
end

-- Returns the base-36 value of a character.
function Utils.base36Val(c, errorCtx)
  errorCtx = errorCtx or "unknown context"
  local base36 = "0123456789abcdefghijklmnopqrstuvwxyz"
  local index = string.find(base36, c)
  if not index then
    error("Invalid base36 char: " .. c .. ", context: " .. errorCtx)
  end
  return index - 1  -- Lua is 1-based, so we subtract 1 to get a zero-based index.
end

-- Encodes a number to a base-36 character. Clamps it if needed
-- to the range 0-35.
function Utils.toBase36Digit(val)
  if type(val) ~= "number" then
    error("Value must be a number, got: " .. type(val))
  end
  val = math.min(math.max(val, 0), 35)  -- Clamp to 0-35
  return string.sub("0123456789abcdefghijklmnopqrstuvwxyz", val + 1, val + 1)
end

function Utils.approach(a, b, absDelta)
  if a < b then
    return math.min(a + absDelta, b)
  elseif a > b then
    return math.max(a - absDelta, b)
  else
    return a  -- already equal
  end
end

function Utils.setLocalX(thing, lx)
  local _, y, z = thing:getLocalPosition()
  thing:setLocalPosition(lx, y, z)
end

function Utils.setLocalY(thing, ly)
  local x, _, z = thing:getLocalPosition()
  thing:setLocalPosition(x, ly, z)
end

function Utils.setLocalZ(thing, lz)
  local x, y, _ = thing:getLocalPosition()
  thing:setLocalPosition(x, y, lz)
end

-- Clamps the magnitude of a vector (vx, vz) to a maximum length.
function Utils.clampMagnitude(vx, vz, maxLength)
  local length = math.sqrt(vx * vx + vz * vz)
  if length > maxLength then
    return vx * maxLength / length, vz * maxLength / length
  end
  return vx, vz  -- Already within bounds
end

-- Normalizes a vector (vx, vz) to have a length of 1.
function Utils.normalize(vx, vz)
  local mag = math.sqrt(vx * vx + vz * vz)
  if mag > 0.00001 then
    return vx / mag, vz / mag
  end
  return 0, 0
end

-- Validates that a value matches a spec. The value is the value you want
-- to validate, and the spec is as follows:
--   "number" - a number
--   "int" - an integer number
--   "number:0,100" - a number between 0 and 100 (inclusive)
--   "int:0,100" - an integer number between 0 and 100 (inclusive)
--   "boolean" - a boolean
--   "string" - a string
--   "string:regex" - a string that matches the given regex
--   "string!" - a non-empty string
--   "array:spec" - an array where each element matches the given spec
--   "array!:spec" - a non-empty array where each element matches the given spec
--   "table" - any table
--   { key1=spec, key2=spec, key3=spec } - a table with specific keys,
--     where each key's value must match the corresponding spec. The presence
--     of keys not specified in the spec are considered an error.
--
-- Any type can have a "?" suffix to make it optional, that is, the value
-- can be nil (or not present in the table). So for example "int?" means
-- an integer or nil, "string?:A-Z+" means a string that matches A-Z+ or nil.
--
-- Any spec can also have alternatives, formatted as "spec|spec|...".
--
-- path: optional, for debugging purposes, it indicates the path to the value
-- being validated.
function Utils.validate(value, spec, path)
  path = path or "value"
  
  -- Check if spec is optional (suffixed with "?")
  local isOptional = false
  local originalSpec = spec
  if type(spec) == "string" and string.sub(spec, -1) == "?" then
    isOptional = true
    spec = string.sub(spec, 1, -2)  -- Remove the "?" suffix
  end
  
  -- If value is nil and spec is optional, it's valid
  if value == nil then
    if isOptional then
      return  -- Valid
    else
      error("Validation failed: " .. path .. " is required but got nil")
    end
  end
  
  -- Handle alternative specs (spec|spec|...)
  if type(spec) == "string" and string.find(spec, "|") then
    local alternatives = {}
    for alt in string.gmatch(spec, "([^|]+)") do
      table.insert(alternatives, alt)
    end
    
    local errors = {}
    for _, alt in ipairs(alternatives) do
      local success, err = pcall(Utils.validate, value, alt, path)
      if success then
        return  -- Valid - one of the alternatives matched
      else
        table.insert(errors, err)
      end
    end
    
    -- None of the alternatives matched, create a combined error message
    local errorMsg = "Validation failed: " .. path .. " did not match any of the alternatives:"
    for i, err in ipairs(errors) do
      errorMsg = errorMsg .. "\n  Alternative " .. i .. ": " .. err
    end
    error(errorMsg)
  end
  
  -- If spec is a table, validate as object schema
  if type(spec) == "table" then
    if type(value) ~= "table" then
      error("Validation failed: " .. path .. " expected table but got " .. type(value))
    end
    
    -- Check that all required keys are present and valid
    for key, keySpec in pairs(spec) do
      local keyPath = path .. "." .. tostring(key)
      Utils.validate(value[key], keySpec, keyPath)
    end
    
    -- Check that no extra keys are present
    for key, _ in pairs(value) do
      if spec[key] == nil then
        error("Validation failed: " .. path .. " has unexpected key '" .. tostring(key) .. "'")
      end
    end
    
    return  -- Valid
  end
  
  -- Handle string specs
  if type(spec) ~= "string" then
    error("Validation failed: Invalid spec type " .. type(spec) .. " for " .. path)
  end
  
  -- Parse spec string
  local specType, constraint = string.match(spec, "^([^:]+):?(.*)$")
  if not specType then
    error("Validation failed: Invalid spec format '" .. spec .. "' for " .. path)
  end
  
  -- Validate based on spec type
  if specType == "number" then
    if type(value) ~= "number" then
      error("Validation failed: " .. path .. " expected number but got " .. type(value))
    end
    if constraint and constraint ~= "" then
      local min, max = string.match(constraint, "^([%d%.%-]+),([%d%.%-]+)$")
      if min and max then
        local minVal, maxVal = tonumber(min), tonumber(max)
        if not minVal or not maxVal then
          error("Validation failed: Invalid number range constraint '" .. constraint .. "' for " .. path)
        end
        if value < minVal or value > maxVal then
          error("Validation failed: " .. path .. " must be between " .. minVal .. " and " .. maxVal .. " but got " .. value)
        end
      else
        error("Validation failed: Invalid number constraint format '" .. constraint .. "' for " .. path)
      end
    end
    
  elseif specType == "int" then
    if type(value) ~= "number" or value ~= math.floor(value) then
      error("Validation failed: " .. path .. " expected integer but got " .. type(value) .. 
            (type(value) == "number" and " (non-integer)" or ""))
    end
    if constraint and constraint ~= "" then
      local min, max = string.match(constraint, "^([%d%-]+),([%d%-]+)$")
      if min and max then
        local minVal, maxVal = tonumber(min), tonumber(max)
        if not minVal or not maxVal then
          error("Validation failed: Invalid integer range constraint '" .. constraint .. "' for " .. path)
        end
        if value < minVal or value > maxVal then
          error("Validation failed: " .. path .. " must be between " .. minVal .. " and " .. maxVal .. " but got " .. value)
        end
      else
        error("Validation failed: Invalid integer constraint format '" .. constraint .. "' for " .. path)
      end
    end
    
  elseif specType == "boolean" then
    if type(value) ~= "boolean" then
      error("Validation failed: " .. path .. " expected boolean but got " .. type(value))
    end
    
  elseif specType == "string" then
    if type(value) ~= "string" then
      error("Validation failed: " .. path .. " expected string but got " .. type(value))
    end
    if constraint and constraint ~= "" then
      -- Treat constraint as regex pattern
      if not string.match(value, constraint) then
        error("Validation failed: " .. path .. " string '" .. value .. "' does not match pattern '" .. constraint .. "'")
      end
    end
    
  elseif specType == "string!" then
    if type(value) ~= "string" then
      error("Validation failed: " .. path .. " expected non-empty string but got " .. type(value))
    end
    if #value == 0 then
      error("Validation failed: " .. path .. " expected non-empty string but got empty string")
    end
    
  elseif specType == "array" or specType == "array!" then
    if type(value) ~= "table" then
      error("Validation failed: " .. path .. " expected array but got " .. type(value))
    end
    
    -- Check if it's a proper array (sequential integer keys starting from 1)
    local count = 0
    for k, _ in pairs(value) do
      count = count + 1
      if type(k) ~= "number" or k ~= count then
        error("Validation failed: " .. path .. " expected array but got table with non-sequential keys")
      end
    end
    
    -- Check for non-empty constraint
    if specType == "array!" and count == 0 then
      error("Validation failed: " .. path .. " expected non-empty array but got empty array")
    end
    
    -- Validate each element if constraint is provided
    if constraint and constraint ~= "" then
      for i, item in ipairs(value) do
        local itemPath = path .. "[" .. i .. "]"
        Utils.validate(item, constraint, itemPath)
      end
    end
    
  elseif specType == "table" then
    if type(value) ~= "table" then
      error("Validation failed: " .. path .. " expected table but got " .. type(value))
    end
    
  else
    error("Validation failed: Unknown spec type '" .. specType .. "' for " .. path)
  end
end

-- Calls the given function recursively on the Thing and all its descendants.
function Utils.forThingAndDescendants(thing, func)
  if not thing then return end
  func(thing)  -- Call the function on the current Thing
  local children = thing:getChildren()
  for _, child in ipairs(children) do
    Utils.forThingAndDescendants(child, func)  -- Recursively call on each child
  end
end