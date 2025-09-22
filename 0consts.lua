-- Map area size, in tiles.
local AREA_WIDTH = 16
local AREA_HEIGHT = 12

-- Natural size of a map tile in world space (as in, the size of the
-- Thing representing the tile), WITHOUT taking the scale into account.
local TILE_SIZE_UNSCALED = 16
-- Size of a map tile, in world space.
local TILE_SIZE = 16
-- Thus the scale of a tile must be:
local TILE_SCALE = TILE_SIZE / TILE_SIZE_UNSCALED

-- Tile types in the map.
-- WARNING: map-build.js parses this file looking for TT_* definitions,
-- so don't get too creative with syntax.
local TT_WATER = 0
local TT_GRASS = 1
local TT_DIRT = 2
local TT_ROCK = 3
local TT_WALL = 4
local TT_BRIDGE = 5
local TT_TREE = 6
local TT_TALLGRASS = 7
local TT_CORN = 8
local TT_WOODFLOOR = 9
local TT_PAVEMENT = 10
local TT_SAND = 11
local TT_CAVE = 12
local TT_SWAMP = 13
local TT_SWAMP_ROCK = 14
local TT_LADDER_DOWN = 15
local TT_SAND_ROCK = 16
local TT_SAND_GRASS = 17
local TT_PALM = 18
local TT_PALM_G = 19
local TT_BOOKSHELF = 20
local TT_SNOW = 21
local TT_SNOW_GRASS = 22
local TT_SNOW_TREE = 23
local TT_SNOW_ROCK = 24
local TT_ICE = 25
local TT_INVBARRIER = 26

-- Types of entity
local ET_ANT = 0
local ET_FIRE_ANT = 1
local ET_BAT = 2
local ET_SCORPION = 3
local ET_SIGN = 12
local ET_SWORD = 13
local ET_FOUNTAIN = 14
local ET_CHEST = 15
local ET_DOOR = 16
local ET_DOOR_LOCKED = 17
local ET_BARS = 18
local ET_LEVER = 19
local ET_WELL = 20
local ET_BOOK = 21
local ET_SHIP = 22
local ET_LAVENDER = 23
local ET_NPC_1 = 24
local ET_NPC_2 = 25
local ET_NPC_3 = 26
local ET_NPC_4 = 27
local ET_NPC_5 = 28
local ET_NPC_6 = 29
local ET_FIREBUSH = 30
local ET_NPC_ARCHITECT = 31
local ET_GATE = 32
local ET_GEMINI = 33


-- Entities >= 128 are entities created at runtime that can't
-- be placed in the map (spawned by enemies, dropped loot, etc).
local ET_FIREBALL = 128
local ET_GOLD_PIECE = 129
local ET_CHEST_OPEN = 130
local ET_DOOR_OPEN = 131
local ET_LEVER_PULLED = 132
local ET_WELL_DRAINED = 133
local ET_GATE_OPEN = 134
local ET_FINAL_BOSS = 135
local ET_FIREBALL_FAST = 136
local ET_GOLD_PILE = 137

-- Types of items. Must correspond to the indices of the frames
-- in the inventory item Things.
local IT_SWORD = 1
local IT_QUESTLOG = 2
local IT_POTION = 3
local IT_TORCH = 4
local IT_PERFUME = 5
local IT_MAP = 6
local IT_LAVENDER = 8
local IT_FIREFRUIT = 9
local IT_KEY = 10
local IT_BOOK = 11
local IT_ASTROLABE = 12
local IT_MAX = 16

-- Tile flags. These are bits that tiles can have that indicate any
-- special attributes that they have. 
local TF_CLEAR = 1 << 1      -- Tile is clear (that is, can be walked on, it's not solid).
local TF_OCCLUDING = 1 << 2  -- Tile graphics blocks the view of what's behind it
local TF_STINKY = 1 << 3     -- Tile damages the player when stepped on
local TF_SLIPPERY = 1 << 4   -- Tile is slippery (like ice)

-- Possible persisted flags indicating the state of the game.
-- Each is a single character, so they can be concatenated into a string.
local SSF_TOWER_GATE = "A"  -- tower gate opened?
local SSF_FINAL_GATE = "B"  -- final gate at top of tower opened?

-- Field names in savegame (must be short to save space)
local PSF_VERSION = "ver"
local PSF_AREA_X = "b"
local PSF_AREA_Y = "c"
local PSF_QUESTF = "d"
local PSF_CENTS = "e"  -- consumed entities (comma-separated string)
local PSF_EUPGRADE = "f" -- equipment upgrades (sword)
-- (more general fields here, as needed)
local PSF_X = "n"
local PSF_Z = "o"
local PSF_HP = "p"
local PSF_HP_MAX = "q"
local PSF_GOLD = "r"
local PSF_INVENTORY = "s"
local PSF_EQUIPPED = "t"
local PSF_MQS = "u"  -- main quest state (int)
-- (more player fields here, as needed)

-- MAIN QUEST STATE
-- This is a single integer that indicates in what step of the main quest
-- the player is. This advances as the player completes the current quest
-- and gets a new quest.

-- Start of game (the quest is, so to say, to pick up sword).
local MQS_TO_SWORD = 0
-- Sword picked up, must now talk to the Torch Maker
local MQS_TO_TORCHMAKER = 1
-- Talked to the Torch Maker and got the fire fruits quest
local MQS_GATHER_FRUIT = 2
-- Collected all necessary Fire Fruits and must now return to the Torch Maker
local MQS_RET_TO_TORCHMAKER = 3
-- Returned to Torch Maker with the fruits and got the torch
-- Must now talk to the mayor
local MQS_TO_HB_MAYOR = 4
-- Talked to mayor of HB and got mission to go to Northshore via the tunnel.
local MQS_TO_TUNNEL = 5
-- Passed through tunnel and emerged in the Northshore side. Must now
-- proceed to talk to the Northshore mayor.
local MQS_TO_NS_MAYOR = 6
-- Talked to Northshore mayor and got mission to go find the Architect.
local MQS_FIND_ARCHITECT = 7
-- Talked to the Architect in the library, he asked player to get the book
-- from the dark part of the library.
local MQS_GET_BOOK = 8
-- Got the book, didn't yet return to the Architect in the library.
local MQS_RET_BOOK = 9
-- Returned the book to the Architect, he told the player to meet in Highbridge
-- and talk to the mayor there.
local MQS_RET_TO_HB = 10
-- Player talked to the mayor of Highbridge and she says the Architect
-- fixed the bridge to the east! She tells the player go to talk to the perfume
-- maker (just arrived in town) and see if they can make her some lavender
-- perfume.
local MQS_TO_PERFUMER = 11
-- The Perfumer tells the player to go East and gather some lavender
-- and bring it back so they can make perfume.
local MQS_GATHER_LAVENDER = 12
-- Gathered the necessary lavender flowers, must now return to the Perfumer.
local MQS_RET_TO_PERFUMER = 13
-- The player returned to the Perfumer and got the perfume.
-- They are now told to go deliver the perfume to the mayor.
local MQS_PERFUME_TO_HB_MAYOR = 14
-- The mayor says she got terrible news in the meantime: the Bridge Architect
-- fell prey to the book's curse is now trying to open a bridge to the underworld
-- and destroy the world, etc. She says the player must go find the Astrolabe
-- in the western swamp, then use it to sail to the Winter Lands to find him.
-- She tells him to keep the perfume and use it to enter the swamp.
local MQS_FIND_ASTROLABE = 15
-- Player found the astrolabe and must now return to the Highbridge Mayor
local MQS_ASTROLABE_TO_HB_MAYOR = 16
-- Player told to go to the ship to sail to the Winter Lands.
local MQS_TO_SHIP = 17
-- Player sailed to the Winter Lands and must now find the Bridge Architect
-- at the top of the tower.
local MQS_TO_END = 18

local MQS_INTRO = 0         -- The initial state of the game
local MQS_CHAPTER_1 = 1     -- Goal: Essence of Rules
local MQS_CHAPTER_2 = 2     -- Goal: Essence of the World
local MQS_CHAPTER_3 = 3     -- Goal: Essence of the Character
local MQS_CHAPTER_4 = 4     -- Goal: Essence of the Story
local MQS_CHAPTER_5 = 5     -- Goal: Essence of Failure
