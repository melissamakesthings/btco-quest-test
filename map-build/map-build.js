// MAP BUILDER
// Converts a Tiled TMX map into a Lua map data file.
// Usage: node map-build.js input.tmx output.lua

const fs = require("fs" );
const path = require("path");

const AREA_WIDTH = 16; // Width of an area in tiles
const AREA_HEIGHT = 12; // Height of an area in tiles

// Pseudo-tile number corresponding to ETYPE 0.
const ENT_ETYPE_BASE = 36;

// Information about each tile type.
// This is loaded by parsing 0consts.lua and area.lua files.
const tileInfo = {};

// Entity type constants loaded from 0consts.lua
const entityTypes = {};

async function main() {
  if (process.argv.length < 4) {
    console.error("Usage: node map-build.js input.tmx output.lua");
    return;
  }

  loadTileInfo();

  const inputFile = process.argv[2];
  const outputFile = process.argv[3];
  const tmxData = fs.readFileSync(inputFile, "utf8");

  console.log(`Input TMX file: ${inputFile}`);
  console.log(`Output Lua file: ${outputFile}`);

  const baseName = path.basename(inputFile, path.extname(inputFile));
  console.log(`Base name: ${baseName}`);

  // Get layer dimensions.
  let m = tmxData.match(/<layer.*?width="(\d+)" height="(\d+)"/);
  if (!m) {
    console.error("Invalid TMX file format: missing layer dimensions.");
    return;
  }
  const width = parseInt(m[1]);
  const height = parseInt(m[2]);

  if (width % AREA_WIDTH !== 0 || height % AREA_HEIGHT !== 0) {
    console.error(`Map dimensions (${width}x${height}) must be multiples of area size (${AREA_WIDTH}x${AREA_HEIGHT}).`);
    return;
  }

  const widthAreas = Math.floor(width / AREA_WIDTH);
  const heightAreas = Math.floor(height / AREA_HEIGHT);

  console.log(`Map dimensions: ${width}x${height} (${widthAreas}x${heightAreas} areas)`);

  // Get CSV data for tiles.
  m = tmxData.match(/<layer .*? name="Tiles".*?<data encoding="csv">(.*?)<\/data>/s);
  if (!m || !m[1]) {
    console.error("No CSV data found in the TMX file.");
    return;
  }
  const tilesCsv = m[1].trim().split(/\s*,\s*/);
  if (tilesCsv.length !== width * height) {
    console.error("Tiles CSV data does not match layer dimensions.");
    return;
  }
  const tileMap = parseMapFromCSVData(tilesCsv, width, height);

  // Get CSV data for entities.
  m = tmxData.match(/<layer .*? name="Entities".*?<data encoding="csv">(.*?)<\/data>/s);
  if (!m || !m[1]) {
    console.error("No CSV data found in the TMX file.");
    return;
  }
  const entsCsv = m[1].trim().split(/\s*,\s*/);
  if (entsCsv.length !== width * height) {
    console.error("Ents CSV data does not match layer dimensions.");
    return;
  }
  const entMap = parseMapFromCSVData(entsCsv, width, height);

  const outputLua = [
    `-- Map data for ${path.basename(inputFile)}`,
    `MAPDATA = {`,
    `  widthAreas = ${widthAreas},`,
    `  heightAreas = ${heightAreas},`,
    `  areas = {`,
  ];

  // Now process the map area by area (each area is 16x12 tiles each).
  for (let areaY = 0; areaY < heightAreas; areaY++) {
    for (let areaX = 0; areaX < widthAreas; areaX++) {
      const areaKey = `${areaX},${areaY}`;
      validateArea(tileMap, entMap, areaX, areaY, widthAreas, heightAreas);
      const areaData = exportArea(tileMap, entMap, areaX, areaY);
      outputLua.push(`    ["${areaKey}"] = "${areaData}",`);
    }
  }
  outputLua.push("  },");
  outputLua.push("}");

  fs.writeFileSync(outputFile, outputLua.join("\n"), "utf8");
  console.log(`Map data exported to ${outputFile}`);
}

function loadTileInfo() {
  // Parse 0consts.lua to get TT_* tile type constants and ET_* entity type constants
  const constsPath = path.join(path.dirname(__filename), "..", "0consts.lua");
  const constsContent = fs.readFileSync(constsPath, "utf8");
  
  // Extract TT_* constants (e.g., "local TT_WATER = 0")
  const ttRegex = /local\s+TT_(\w+)\s*=\s*(\d+)/g;
  let match;
  while ((match = ttRegex.exec(constsContent)) !== null) {
    const tileName = match[1];
    const tileNumber = parseInt(match[2]);
    tileInfo[tileNumber] = { name: tileName };
  }
  
  // Extract ET_* constants (e.g., "local ET_FOUNTAIN = 14")
  const etRegex = /local\s+ET_(\w+)\s*=\s*(\d+)/g;
  while ((match = etRegex.exec(constsContent)) !== null) {
    const entityName = match[1];
    const entityNumber = parseInt(match[2]);
    entityTypes[entityName] = entityNumber;
  }
  
  // Parse area.lua to get tile recipes and flags
  const areaPath = path.join(path.dirname(__filename), "..", "area.lua");
  const areaContent = fs.readFileSync(areaPath, "utf8");
  
  // Extract tile recipes that have TF_CLEAR flag
  // Look for lines like: [TT_GRASS] = { base = 2, flags = TF_CLEAR },
  const recipeRegex = /\[TT_(\w+)\]\s*=\s*\{[^}]*flags\s*=\s*([^,}]*)/g;
  while ((match = recipeRegex.exec(areaContent)) !== null) {
    const tileName = match[1];
    const flagsExpression = match[2].trim();
    
    // Find the corresponding tile number from our TT_* constants
    const tileNumber = Object.keys(tileInfo).find(num => 
      tileInfo[num].name === tileName
    );
    
    if (tileNumber !== undefined) {
      // Check if the flags expression contains TF_CLEAR
      if (flagsExpression.includes("TF_CLEAR")) {
        tileInfo[tileNumber].isClear = true;
      }
    }
  }
  
  console.log("Loaded tile info:", tileInfo);
  console.log("Loaded entity types:", entityTypes);
}

function parseMapFromCSVData(csvData, width, height) {
  if (csvData.length !== width * height) {
    throw new Error(`CSV data length ${csvData.length} does not match map dimensions (${width}x${height}).`);
  }
  const map = {};
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      // Subtract one because Tiled uses 1-based indexing for tiles.
      // But 0 in tiled means no tile, which we represent as our tile 0.
      map[`${x},${y}`] = Math.max(0, parseInt(csvData[y * width + x]) - 1);
    }
  }
  return map;
}

// Helper function to validate a single tile value
function validateTileValue(tile, worldX, worldY, areaX, areaY) {
  if (tile < 0 || tile >= ENT_ETYPE_BASE) {
    throw new Error(`Invalid tile value ${tile} at (${worldX},${worldY}) in area (${areaX},${areaY}). Must be in range 0-${ENT_ETYPE_BASE - 1}.`);
  }
  
  if (tileInfo[tile] === undefined) {
    throw new Error(`Unknown tile type ${tile} at (${worldX},${worldY}) in area (${areaX},${areaY}). Not defined in constants.`);
  }
}

// Helper function to validate a single entity value
function validateEntityValue(ent, worldX, worldY, areaX, areaY) {
  if (ent !== 0 && ent < ENT_ETYPE_BASE) {
    throw new Error(`Invalid entity value ${ent} at (${worldX},${worldY}) in area (${areaX},${areaY}). Must be 0 or >= ${ENT_ETYPE_BASE}.`);
  }
}

// Helper function to get tile clearness
function isTileClear(tileMap, worldX, worldY) {
  const tile = tileMap[`${worldX},${worldY}`] || 0;
  return tileInfo[tile] && tileInfo[tile].isClear === true;
}

// Helper function to validate border clearness between two tiles
function validateBorderClearness(tileMap, worldX1, worldY1, worldX2, worldY2, areaX, areaY, direction) {
  const clear1 = isTileClear(tileMap, worldX1, worldY1);
  const clear2 = isTileClear(tileMap, worldX2, worldY2);
  
  if (clear1 !== clear2) {
    throw new Error(`Border clearness mismatch at ${direction} edge of area (${areaX},${areaY}): tile (${worldX1},${worldY1}) clear=${clear1} vs adjacent tile (${worldX2},${worldY2}) clear=${clear2}`);
  }
}

// Helper function to validate fountain surroundings
function validateFountainSurroundings(tileMap, entMap, worldX, worldY, areaX, areaY) {
  // Check all 8 neighboring tiles
  const neighbors = [
    [-1, -1], [0, -1], [1, -1],  // Top row
    [-1,  0],          [1,  0],  // Middle row (skip center)
    [-1,  1], [0,  1], [1,  1]   // Bottom row
  ];
  
  for (const [dx, dy] of neighbors) {
    const neighborX = worldX + dx;
    const neighborY = worldY + dy;
    
    // Check if the neighboring tile is clear
    if (!isTileClear(tileMap, neighborX, neighborY)) {
      throw new Error(`Fountain at (${worldX},${worldY}) in area (${areaX},${areaY}) has non-clear tile at neighbor (${neighborX},${neighborY})`);
    }
    
    // Check if there's an entity on the neighboring tile
    const neighborEnt = entMap[`${neighborX},${neighborY}`] || 0;
    if (neighborEnt !== 0) {
      throw new Error(`Fountain at (${worldX},${worldY}) in area (${areaX},${areaY}) has entity ${neighborEnt} at neighbor (${neighborX},${neighborY})`);
    }
  }
}

// Checks that the given area is valid.
function validateArea(tileMap, entMap, areaX, areaY, mapWidthAreas, mapHeightAreas) {
  // Validate all tiles and entities in the area
  for (let y = 0; y < AREA_HEIGHT; y++) {
    for (let x = 0; x < AREA_WIDTH; x++) {
      const worldX = areaX * AREA_WIDTH + x;
      const worldY = areaY * AREA_HEIGHT + y;
      
      const tile = tileMap[`${worldX},${worldY}`] || 0;
      const ent = entMap[`${worldX},${worldY}`] || 0;
      
      validateTileValue(tile, worldX, worldY, areaX, areaY);
      validateEntityValue(ent, worldX, worldY, areaX, areaY);
      
      // Check if this is a fountain entity and validate its surroundings
      const etype = ent - ENT_ETYPE_BASE;
      if (etype >= 0) {
        // Look up ET_FOUNTAIN from parsed constants
        if (entityTypes.FOUNTAIN === undefined) {
          throw new Error("ET_FOUNTAIN constant not found in 0consts.lua");
        }
        
        if (etype === entityTypes.FOUNTAIN) {
          validateFountainSurroundings(tileMap, entMap, worldX, worldY, areaX, areaY);
        }
      }
    }
  }
  
  // Validate border clearness with adjacent areas
  // Check right border (if not rightmost area)
  if (areaX < mapWidthAreas - 1) {
    for (let y = 0; y < AREA_HEIGHT; y++) {
      const thisWorldX = (areaX + 1) * AREA_WIDTH - 1; // Rightmost tile of this area
      const nextWorldX = (areaX + 1) * AREA_WIDTH;     // Leftmost tile of next area
      const worldY = areaY * AREA_HEIGHT + y;
      
      validateBorderClearness(tileMap, thisWorldX, worldY, nextWorldX, worldY, areaX, areaY, "right");
    }
  }
  
  // Check bottom border (if not bottommost area)
  if (areaY < mapHeightAreas - 1) {
    for (let x = 0; x < AREA_WIDTH; x++) {
      const worldX = areaX * AREA_WIDTH + x;
      const thisWorldY = (areaY + 1) * AREA_HEIGHT - 1; // Bottommost tile of this area
      const nextWorldY = (areaY + 1) * AREA_HEIGHT;     // Topmost tile of next area
      
      validateBorderClearness(tileMap, worldX, thisWorldY, worldX, nextWorldY, areaX, areaY, "bottom");
    }
  }
}

// Exports an area of the map as a string.
function exportArea(tileMap, entMap, areaX, areaY) {
  const tiles = [];
  const entList = [];
  for (let y = 0; y < AREA_HEIGHT; y++) {
    for (let x = 0; x < AREA_WIDTH; x++) {
      const tile = tileMap[`${areaX * AREA_WIDTH + x},${areaY * AREA_HEIGHT + y}`] || 0;
      const ent = entMap[`${areaX * AREA_WIDTH + x},${areaY * AREA_HEIGHT + y}`] || 0;
      tiles.push(tile);
      // Is there an entity here? Add to entity list if so.
      const etype = ent - ENT_ETYPE_BASE;
      if (etype >= 0) entList.push({ x, y, etype });
    }
  }

  let output = "";

  const BASE36_CHARS = "0123456789abcdefghijklmnopqrstuvwxyz";

  // Do some RLE encoding
  for (let i = 0; i < tiles.length; i++) {
    let runLength = getRunLength(tiles, i, 99);
    // Look up the tile code (base-36).
    const tileCode = BASE36_CHARS[tiles[i]];
    if (tileCode === undefined) throw new Error(`Invalid tile value: ${tiles[i]}`);
    // Do an RLE run if it's worth it.
    if (runLength > 4 && runLength < 10) {
      output += `*0${runLength}${tileCode}`;
      // Skip the next runLength - 1 elements
      i += runLength - 1;
    } else if (runLength >= 10) {
      output += `*${runLength}${tileCode}`;
      // Skip the next runLength - 1 elements
      i += runLength - 1;
    } else {
      output += `${tileCode}`;
    }
  }

  // Add entities to the output.
  if (entList.length > 0) output += "|";  // Separator for entities section
  for (const ent of entList) {
    const entCode = BASE36_CHARS[ent.etype];
    const xCode = BASE36_CHARS[ent.x];
    const yCode = BASE36_CHARS[ent.y];
    if (entCode === undefined) throw new Error(`Invalid entity type: ${ent.etype}`);
    if (xCode === undefined) throw new Error(`Invalid entity x coordinate: ${ent.x}`);
    if (yCode === undefined) throw new Error(`Invalid entity y coordinate: ${ent.y}`);
    // Add a triplet of entity type, x, and y, encoded in base-36.
    output += `${entCode}${xCode}${yCode}`;
  }

  return output;
}

// Returns how many elements of the given array are the same element,
// starting from the given index.
function getRunLength(array, index, maxLength) {
  const value = array[index];
  let length = 1;
  while (length < maxLength &&
      index + length < array.length &&
      array[index + length] === value) {
    length++;
  }
  return length;
}

main();