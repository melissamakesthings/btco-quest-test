-- Manages the current map and area

Area = {
  -- Y position for base and overlay tiles
  BASE_TILE_Y = -8 * TILE_SCALE,
  OVERLAY_TILE_Y = 0,

  -- Correct base scale for tile bases and overlays.
  BASE_TILE_SCALE = TILE_SIZE / TILE_SIZE_UNSCALED,

  -- Width and height of current map, measured in areas.
  mapWidthAreas = nil, mapHeightAreas = nil,
  -- Coordinates of the current area, nil if not loaded.
  areaX = nil, areaY = nil,
  -- Tiles in the current area. These are indexed by tile coordinates mx .. "," .. my.
  tiles = {},
  -- Things that represent tile bases.
  tileBaseThings = {},
  -- Things that represent tile overlays.
  tileOverlayThings = {},

  -- For performance reasons (and to avoid crashes) we only create one row
  -- of tiles per frame, so this tracks what's the next row of tiles to create.
  nextRowToCreate = nil,

  -- Area lighting ("BRIGHT", "DARK", "DIM")
  lighting = "BRIGHT",
}

-- Tile "recipes" for rendering tiles based on bases and overlays.
-- Also contains data about the corresponding tile type, such as
-- whether or not it's walkable and so on.
Area.recipes = {
  -- WARNING: map-build.js parses this file looking for "TF_CLEAR" in the same
  -- line as a TT_* tile definition to know that the tile is clear.
  [TT_WATER] = { base = 1, flags = 0 },
  [TT_GRASS] = { base = 2, flags = TF_CLEAR },
  [TT_DIRT] = { base = 3, baseTint = "#ffd88d", flags = TF_CLEAR },
  [TT_ROCK] = { base = 2, overlay = 2, flags = 0 },
  [TT_WALL] = { base = 2, overlay = 1, flags = TF_OCCLUDING },
  [TT_BRIDGE] = { base = 5, flags = TF_CLEAR },
  [TT_TREE] = { base = 2, overlay = 3, flags = 0 },
  [TT_TALLGRASS] = { base = 2, overlay = 4, flags = TF_CLEAR },
  [TT_CORN] = { base = 2, overlay = 5, flags = TF_CLEAR },
  [TT_WOODFLOOR] = { base = 4, flags = TF_CLEAR },
  [TT_PAVEMENT] = { base = 6, baseTint = "#a0a0b0", flags = TF_CLEAR },
  [TT_SAND] = { base = 3, baseTint = "#fff8b9", flags = TF_CLEAR },
  [TT_CAVE] = { base = 2, overlay = 6, overlayScale = 1.8, flags = 0},
  [TT_SWAMP] = { base = 7, flags = TF_CLEAR | TF_STINKY },
  [TT_SWAMP_ROCK] = { base = 7, overlay = 2, flags = 0 },
  [TT_LADDER_DOWN] = { base = 8, flags = 0 },
  [TT_SAND_ROCK] = { base = 3, overlay = 2, flags = 0, baseTint = "#fff8b9", overlayTint = "#bbaa66" },
  [TT_SAND_GRASS] = { base = 3, overlay = 4, flags = TF_CLEAR, baseTint = "#fff8b9", overlayTint = "#bbaa66" },
  [TT_PALM] = { base = 3, overlay = 7, overlayYaw = 45, flags = 0, baseTint = "#fff8b9" },
  [TT_PALM_G] = { base = 2, overlay = 7, overlayYaw = 45, flags = 0 },
  [TT_BOOKSHELF] = { base = 4, overlay = 8, flags = TF_OCCLUDING },
  [TT_SNOW] = { base = 3, flags = TF_CLEAR },
  [TT_SNOW_GRASS] = { base = 3, overlay = 4, overlayTint = "#888888", flags = TF_CLEAR },
  [TT_SNOW_TREE] = { base = 3, overlay = 9 },
  [TT_SNOW_ROCK] = { base = 3, overlay = 2 },
  [TT_ICE] = { base = 9, flags = TF_CLEAR | TF_SLIPPERY },
  [TT_INVBARRIER] = { base = 3, baseTint = "#ffd88d" },
}

function Area.init()
  Area.tileBaseThings = getThing("TileBases"):getChildren()
  if #Area.tileBaseThings ~= AREA_WIDTH * AREA_HEIGHT then
    error("TileBases must have exactly " .. (AREA_WIDTH * AREA_HEIGHT) .. " children")
  end
  -- Get the tile overlay things.
  Area.tileOverlayThings = getThing("TileOverlays"):getChildren()
  if #Area.tileOverlayThings ~= AREA_WIDTH * AREA_HEIGHT then
    error("TileOverlays must have exactly " .. (AREA_WIDTH * AREA_HEIGHT) .. " children")
  end
  -- Ensure the scale is right on all of them
  for _, thing in ipairs(Area.tileBaseThings) do thing:setScale(Area.BASE_TILE_SCALE) end
  for _, thing in ipairs(Area.tileOverlayThings) do thing:setScale(Area.BASE_TILE_SCALE) end

  -- Start from a clean state.
  Area.reset()
end

function Area.reset()
  Area.mapWidthAreas = nil
  Area.mapHeightAreas = nil
  Area.areaX = nil
  Area.areaY = nil
  Area.tiles = {}
  -- Hide all things.
  for _, thing in ipairs(Area.tileBaseThings) do thing:setPosition(0, -100000, 0) end
  for _, thing in ipairs(Area.tileOverlayThings) do thing:setPosition(0, -100000, 0) end
  Area.lighting = "BRIGHT"
  setRoomLighting("BRIGHT") -- default lighting
end

-- Loads a given area of the single world map.
function Area.load(areaX, areaY)
  -- Start by clearing everything first.
  Area.reset()

  -- Map name is always "world" in single-map mode.
  Area.areaX = areaX
  Area.areaY = areaY
  local md = MAPDATA
  if not md.areas then error("Map has no areas.") end
  if not md.widthAreas or not md.heightAreas then
    error("Map has no dimensions.")
  end
  local areaData = md.areas[areaX .. "," .. areaY]
  if not areaData then error("Area not found in map: " .. areaX .. "," .. areaY) end
  Area.mapWidthAreas = md.widthAreas
  Area.mapHeightAreas = md.heightAreas
  -- Decode the area tiles.
  local i = 0  -- we increment this to 1 before reading (Lua is 1-based).
  local x, y = 0, 0
  local tilesAdded = 0
  local hasEntities = false
  while i < #areaData do -- sic, "<" not "<=" because we increment i before reading
    -- Get the next character.
    i = i + 1
    local c = areaData:sub(i, i)
    local count = 1
    if c == "|" then
      -- Marks the start of the entities section.
      hasEntities = true
      i = i + 1  -- Skip the '|'
      break
    end
    if c == "*" then
      -- RLE sequence "*CCx" meaning CC times the tile x.
      -- Parse the count.
      count = tonumber(areaData:sub(i + 1, i + 2))
      i = i + 3
      c = areaData:sub(i, i) -- Get the tile character.
    end
    -- Get the tile.
    local tile = Utils.base36Val(c, "map area " .. areaX .. "," .. areaY)
    for j = 1, count do
      Area.tiles[x .. "," .. y] = tile
      tilesAdded = tilesAdded + 1
      x = x + 1
      if x >= AREA_WIDTH then
        x = 0
        y = y + 1
      end
    end
  end
  -- Check that we read the entire area.
  if x ~= 0 or y ~= AREA_HEIGHT then
    error("Area data does not match expected dimensions: area ".. areaX .. "," .. areaY .. " x = " .. x .. ", y = " .. y .. " tiles added " .. tilesAdded)
  end

  -- Read the entities section, if there is one, creating each entity as needed.
  if hasEntities then
    while i <= #areaData do
      local ctx = "entData on area " .. areaX .. "," .. areaY
      local etype = Utils.base36Val(areaData:sub(i, i), ctx)
      local mx = Utils.base36Val(areaData:sub(i + 1, i + 1), ctx)
      local my = Utils.base36Val(areaData:sub(i + 2, i + 2), ctx)
      local wx, wz = Area.getTileWorldCenter(mx, my)
  local mapPosition = {areaX = areaX, areaY = areaY, mx = mx, my = my}
      Entities.create(etype, wx, wz, 0, mapPosition)
      i = i + 3 -- Move to the next entity (3 characters per entity).
    end
  end

  -- Play the right music for the area.
  local areaConfig = Area.getAreaConfig(areaX, areaY)
  Music.requestPlay(areaConfig.music or "OVERWORLD")

  -- Set lighting based on area config
  Area.setLighting(areaConfig.lighting or "BRIGHT")

  -- Now create the tiles.
  -- We need to do this over several frames to avoid crashing because the
  -- engine can quickly get overloaded with too many messages.
  Area.nextRowToCreate = 0  -- Start creating from the first row.

  -- Invoke the trigger for this area, if that exists.
  -- NOTE: this handler might change the area tiles, so we must guarantee
  -- that this is called BEFORE we create any area tiles (which is the case,
  -- since we start creating area tiles in the next frame).
  Triggers.handleAreaEnter(areaX, areaY)

  Markers.updateForQuestAndArea()
end

function Area._createTiles()
  if not Area.nextRowToCreate then return end
  local my = Area.nextRowToCreate
  for mx = 0, AREA_WIDTH - 1 do
    local thingIndex = my * AREA_WIDTH + mx + 1 -- Lua is 1-based, so we add 1.
    local tile = Area.tiles[mx .. "," .. my]
    if not tile then error("No tile at coordinates: " .. mx .. "," .. my) end
    -- Get the recipe for this tile type.
    local recipe = Area.recipes[tile]
    if not recipe then error("No recipe for tile type: " .. tile) end
    -- Get the base and overlay things.
    local baseThing = Area.tileBaseThings[thingIndex]
    local overlayThing = Area.tileOverlayThings[thingIndex]
    -- Set their positions.
    local wx, wz = Area.getTileWorldCenter(mx, my)

    if recipe.base then
      baseThing:setFrame(recipe.base)
      baseThing:setTint(recipe.baseTint or "#ffffff")
      baseThing:setPosition(wx, Area.BASE_TILE_Y, wz)
    end
    if recipe.overlay then
      overlayThing:setFrame(recipe.overlay)
      overlayThing:setTint(recipe.overlayTint or "#ffffff")
      overlayThing:setPosition(wx, Area.OVERLAY_TILE_Y, wz)
      -- Apply overlay scale (recipe.overlayScale times BASE_TILE_SCALE, or just BASE_TILE_SCALE if not specified)
      local overlayScale = (recipe.overlayScale or 1) * Area.BASE_TILE_SCALE
      overlayThing:setScale(overlayScale)
      -- Apply overlay yaw rotation (defaults to 0 if not specified)
      local overlayYaw = recipe.overlayYaw or 0
      overlayThing:setLocalRotation(0, overlayYaw, 0)
    end
  end
  Area.nextRowToCreate = Area.nextRowToCreate + 1
  if Area.nextRowToCreate >= AREA_HEIGHT then
    Area.nextRowToCreate = nil  -- No more rows to create.
  end
end

function Area.update()
  if Area.nextRowToCreate then
    Area._createTiles()  -- Create the next row of tiles.
  end
end

-- Returns true if the area is still being loaded (tiles are being created)
function Area.isLoading()
  return Area.nextRowToCreate ~= nil
end

function Area._isTileInBounds(mx, my)
  return mx >= 0 and mx < AREA_WIDTH and my >= 0 and my < AREA_HEIGHT
end

function Area.isWorldPosInBounds(wx, wz)
  local mx, my = Area.tileCoordsForWorldPos(wx, wz)
  return Area._isTileInBounds(mx, my)
end

-- Gets the tile coordinates for a given world position (wx, wz).
function Area.tileCoordsForWorldPos(wx, wz)
  return floor(wx / TILE_SIZE), floor(-wz / TILE_SIZE)
end

-- Gets the world position for a given tile (mx, my) as wx, wz.
function Area.getTileWorldCenter(mx, my)
  return (mx + 0.5) * TILE_SIZE, -(my + 0.5) * TILE_SIZE
end

-- Returns true if the circle at (wx, wz) with the given radius
-- overlaps the tile at (mx, my)
function Area._circleOverlapsTile(wx, wz, radius, mx, my)
  local tileWx, tileWz = Area.getTileWorldCenter(mx, my)
  -- Compute closest distance from circle center to tile bounds
  local dx = math.max(math.abs(tileWx - wx) - TILE_SIZE * 0.5, 0)
  local dz = math.max(math.abs(tileWz - wz) - TILE_SIZE * 0.5, 0)
  local distSq = dx * dx + dz * dz
  return distSq <= radius * radius
end

-- Checks if a given circle, given in world coordinates, overlaps
-- solely on clear tiles, that is, tiles that are not solid.
-- options: table with the following optional fields:
--   allowOob: boolean (default false)
--     If true, it means that the area outside of area bounds is considered
--     "clear" and thus the circle can outside the area bounds.
--     If false, the circle must be fully inside the area bounds.
--   disallowOccluded: boolean (default false)
--     If true, occluded tiles are considered as NOT clear.
--     If false, occluded tiles are treated normally based on their flags.
-- Returns: isClear, blockingTileMx, blockingTileMy
--   isClear: true if the circle is clear, false if blocked
--   blockingTileMx, blockingTileMy: coordinates of the first blocking tile found (nil if clear)
function Area.checkWorldCircle(wx, wz, radius, options)
  options = options or {}
  local allowOob = options.allowOob or false
  local disallowOccluded = options.disallowOccluded or false
  
  local minX = math.floor((wx - radius) / TILE_SIZE)
  local maxX = math.floor((wx + radius) / TILE_SIZE)
  local minY = math.floor((-wz - radius) / TILE_SIZE)
  local maxY = math.floor((-wz + radius) / TILE_SIZE)

  for my = minY, maxY do
    for mx = minX, maxX do
      -- Does this tile really overlap the circle?
      if Area._circleOverlapsTile(wx, wz, radius, mx, my) then
        -- If so, check if it's clear.
        -- note: if allowOob is true, out-of-bounds tiles are considered clear,
        -- otherwise they are considered not clear.
        if not Area._isTileClear(mx, my, allowOob) then 
          return false, mx, my
        end
        -- If disallowOccluded is true, also check if the tile is occluded
        if disallowOccluded and Area._isTileOccluded(mx, my) then
          return false, mx, my
        end
      end
    end
  end

  return true, nil, nil
end

-- Checks if a given tile (mx, my) is clear, that is, it can be walked on.
-- retIfOob
--   Value to return (can be anything) if the tile is out of bounds.
function Area._isTileClear(mx, my, retIfOob)
  local tile = Area.tiles[mx .. "," .. my]
  if not tile then return retIfOob end
  local recipe = Area.recipes[tile]
  if not recipe then return false end
  return (recipe.flags or 0) & TF_CLEAR ~= 0
end

-- Checks if a given tile (mx, my) is occluded, that is, is behind a
-- tile that has the TF_OCCLUDING flag set.
function Area._isTileOccluded(mx, my)
  -- Check if there's an occluding tile directly in front of this tile
  local frontMy = my + 1
  
  local frontTile = Area.tiles[mx .. "," .. frontMy]
  if not frontTile then return false end  -- No tile in front
  
  local frontRecipe = Area.recipes[frontTile]
  if not frontRecipe then return false end  -- No recipe for front tile
  
  return (frontRecipe.flags or 0) & TF_OCCLUDING ~= 0
end

-- Sets the area as dark, bright or dim.
function Area.setLighting(lightMode)
  if lightMode ~= "BRIGHT" and lightMode ~= "DARK" and lightMode ~= "DIM" then
    error("Invalid lighting mode: " .. tostring(lightMode))
  end
  Area.lighting = lightMode
  setRoomLighting(lightMode)
end

-- Convenience function that converts global map coordinates (as seen in the
-- map editor) to area coordinates and tile coordinates within the area.
function Area.globalMapToAreaTileCoords(gx, gz)
  local areaX = floor(gx / AREA_WIDTH)
  local areaY = floor(gz / AREA_HEIGHT)
  local mx = gx % AREA_WIDTH
  local my = gz % AREA_HEIGHT
  return areaX, areaY, mx, my
end

function Area.getAreaConfig(areaX, areaY)
  areaX = areaX or Area.areaX
  areaY = areaY or Area.areaY
  return ALL_AREA_CONFIGS[areaX .. " " .. areaY] or ALL_AREA_CONFIGS["DEFAULT"]
end

-- Sets an area tile. This can only be called from area enter triggers
-- before the area tiles have been created, or it will crash.
function Area.setTile(mx, my, value)
  if Area.nextRowToCreate ~= 0 then error("Area.setTile can only be called before creating tiles") end
  if not Area.tiles[mx .. "," .. my] then
    error("Area.setTile: invalid tile coordinates: " .. mx .. "," .. my)
  end
  Area.tiles[mx .. "," .. my] = value
end
