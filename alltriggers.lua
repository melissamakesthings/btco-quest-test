-- TRIGGERS
-- What to do when stuff happens in the game.
-- Triggers are used to define conditions that trigger a certain callback.
-- Trigger types:
--
-- "AREA <areaX> <areaY>"
--   triggers when the user enters the specified area.
-- "ECOLL <entityType>"
--   triggers when the user collides with an entity of the given type, anywhere
--   in the world.
-- "ECOLL <entityType> AREA <areaX> <areaY>"
--   triggers when the user collides with an entity of the given type, in
--   the specified area.
-- "TILE <tileType>"
--   triggers when the user walks into a solid tile of the given type.
--   The callback receives: function(tileType, mx, my) where mx,my are tile coordinates.
-- "TILE <tileType> AREA <areaX> <areaY>"
--   triggers when the user walks into a solid tile of the given type, in
--   the specified area.
--   The callback receives: function(tileType, mx, my) where mx,my are tile coordinates.
-- "ATRAN <areaX> <areaY> <direction>"
--   triggers when the user attempts to transition from the specified area in the given direction.
--   Direction can be "N", "E", "S", or "W". If the callback returns true, the transition is blocked.
-- "<triggerName>"
--   Global trigger name that can be called from a conversation, etc.

ALL_TRIGGERS = {
  ------------------------------------------------------------------------------
  -- Starting Area (World Map)
  ------------------------------------------------------------------------------
  ["AREA 2 13"] = function()
    -- In this area there is an ET_SWORD entity that the player can pick up,
    -- but after they've picked it up, it should disappear.
    if Player.hasItem(IT_SWORD) then Entities.deleteAllOfType(ET_SWORD) end
  end,
  -- Pick up the sword on the first screen.
  ["ECOLL " .. ET_SWORD] = function(ent)
    -- Sword in the first screen.
    Menu.show({
      text = "You see a shiny sword on the ground.",
      options = { "Pick it up", "Leave it be" },
      typewriter = true,
      callback = function(i)
        if i ~= 1 then return end
        Entities.deleteAllOfType(ET_SWORD)
        Player.addItem(IT_SWORD)
        Player.equipItem(IT_SWORD)
        Triggers.handleGlobalTrigger("GOT_SWORD")
      end
    })
  end,
  ["GOT_SWORD"] = function()
    Sfx.play("SOLVE")
    Menu.showPopup("You picked up the sword! To attack, press [A] or [Space].")
    -- Next step in the quest is to go to Highbridge and talk to the Torch Maker.
    Persister.setMainQuestState(MQS_TO_TORCHMAKER)
  end,
  ["ECOLL " .. ET_NPC_1 .. " AREA 3 13"] = function(ent)
    Dialogues.runDialogue("FIRST")
  end,
  ["AREA 3 13"] = function()
    -- If the player comes here after having talked to the Highbridge Mayor
    -- mayor, the NPC will no longer be there (as they have nothing else to
    -- say).
    if Persister.getMainQuestState() > MQS_TO_HB_MAYOR then
      Entities.deleteAllOfType(ET_NPC_1)
    end
  end,
  ["ECOLL " .. ET_SIGN .. " AREA 3 13"] = function(ent)
    -- Show the sign text.
    Menu.showPopup("Highbridge Village =>")
  end,
  -- NPC just south of Highbridge.
  ["ECOLL " .. ET_NPC_2 .. " AREA 5 14"] = function(ent)
    Dialogues.runDialogue("BEACH_WELL_HINT")
  end,
  -- NPC just south-west of Highbridge.
  ["ECOLL " .. ET_NPC_3 .. " AREA 3 14"] = function(ent)
    Dialogues.runDialogue("SWAMP_WELL_HINT")
  end,


  ------------------------------------------------------------------------------
  -- Swamp (World Map)
  ------------------------------------------------------------------------------
  -- Sign in the swamp.
  ["ECOLL " .. ET_SIGN .. " AREA 1 14"] = function(ent)
    -- Show the sign text.
    Menu.showPopup("Caution: Very Stinky Swamp! You will take damage unless you have something to neutralize the smell!")
  end,
  ["ECOLL " .. ET_SIGN .. " AREA 1 13"] = function(ent)
    -- Show the sign text.
    Menu.showPopup("Caution: Very Stinky Swamp! You will take damage unless you have something to neutralize the smell!")
  end,
  -- Astrolabe chest in swamp.
  ["ECOLL " .. ET_CHEST .. " AREA 0 11"] = function(ent)
    Chest.open(ent, IT_ASTROLABE, 1,
      "You found the Astrolabe! You can return to the Mayor of Highbridge now.")
  end,
  -- Lever in the swamp, north of the Astrolabe chest.
  ["ECOLL " .. ET_LEVER .. " AREA 0 10"] = function(ent)
    Menu.show({
      text = "Pull the lever?",
      options = { "No, leave it", "Yes, pull it!" },
      callback = function(i)
        if i == 2 then
          Barriers.doLever(ent, ET_GATE)
          Menu.showPopup("The gate has opened.")
        end
      end
    })
  end,

  ------------------------------------------------------------------------------
  -- Tunnel entrance area (World Map)
  ------------------------------------------------------------------------------
  ["TILE " .. TT_CAVE .. " AREA 4 11"] = function(tileType, mx, my)
    CaveEntrance.enter(mx, my, 3, 34)
  end,
  ["TILE " .. TT_LADDER_DOWN .. " AREA 4 10"] = function(tileType, mx, my)
    Ladder.climbDown(mx, my, 13, 1)
  end,

  ------------------------------------------------------------------------------
  -- Highbridge Village (World Map)
  ------------------------------------------------------------------------------
  ["ECOLL " .. ET_NPC_2 .. " AREA 5 13"] = function(ent)
    Dialogues.runDialogue("TORCHMAKER")
  end,
  ["ECOLL " .. ET_NPC_6 .. " AREA 5 13"] = function(ent)
    Dialogues.runDialogue("HIGHBRIDGE_MAYOR")
  end,
  ["ECOLL " .. ET_NPC_4 .. " AREA 5 13"] = function(ent)
    Dialogues.runDialogue("POTIONS_MERCHANT")
  end,
  ["ECOLL " .. ET_NPC_3 .. " AREA 5 13"] = function(ent)
    Dialogues.runDialogue("BLACKSMITH")
  end,
  ["ECOLL " .. ET_NPC_5 .. " AREA 5 13"] = function(ent)
    Dialogues.runDialogue("PERFUMER")
  end,
  -- Highbridge village
  ["AREA 5 13"] = function()
    -- Is the perfume maker present?
    -- He's only present when the player returns to Highbridge after meeting
    -- the Architect.
    if Persister.getMainQuestState() < MQS_RET_TO_HB then
      Entities.deleteAllOfType(ET_NPC_5)
    end
  end,
  -- Highbridge bridge
  ["AREA 6 13"] = function()
    -- If the architect quest is done, then the bridge is fixed.
    if Persister.getMainQuestState() >= MQS_RET_TO_HB then
      -- Fix the bridge by adding bridge tiles to fill the gap.
      Area.setTile(5, 5, TT_BRIDGE)
      Area.setTile(6, 5, TT_BRIDGE)
      Area.setTile(7, 5, TT_BRIDGE)
    else
      -- If the bridge isn't fixed yet, the NPC that says the bridge is
      -- fixed won't be present yet.
      Entities.deleteAllOfType(ET_NPC_1)
    end
  end,
  ["ECOLL " .. ET_NPC_1 .. " AREA 6 13"] = function(ent)
    Dialogues.runDialogue("BRIDGE_FIXED_NPC")
  end,
  ["AREA 4 13"] = function()
    -- The perfume maker is only here at the right time.
    if Persister.getMainQuestState() < MQS_TO_PERFUMER then
      Entities.deleteAllOfType(ET_NPC_5)
    end
  end,
  
  ["ATRAN 5 13 N"] = function() return _tryExitHighbridge(0, -16) end,
  ["ATRAN 5 13 S"] = function() return _tryExitHighbridge(0, 16) end,
  ["ATRAN 5 13 E"] = function() return _tryExitHighbridge(-16, 0) end,
  ["ATRAN 5 13 W"] = function() return _tryExitHighbridge(16, 0) end,

  ------------------------------------------------------------------------------
  -- Lavender Fields
  ------------------------------------------------------------------------------
  ["AREA 1 12"] = function()
    if Persister.getMainQuestState() >= MQS_GATHER_LAVENDER then
      -- If it's the right time to collect, the NPC that blocks the way
      -- will be absent.
      Entities.deleteAllOfType(ET_NPC_1)
    end
  end,
  ["ECOLL " .. ET_NPC_1 .. " AREA 1 12"] = function(ent)
    Menu.showPopup("The lavenders aren't in the right season for harvesting yet.")
  end,

  ------------------------------------------------------------------------------
  -- Northshore areas (World Map)
  ------------------------------------------------------------------------------
  ["ECOLL " .. ET_SIGN .. " AREA 4 10"] = function(ent)
    -- Show the sign text.
    Menu.showPopup("This way to Northshore")
  end,
  -- Mayor of Northshore.
  ["ECOLL " .. ET_NPC_6 .. " AREA 4 8"] = function(ent)
    Dialogues.runDialogue("NORTHSHORE_MAYOR")
  end,
  -- Northshore blacksmith
  ["ECOLL " .. ET_NPC_3 .. " AREA 4 8"] = function(ent)
    Dialogues.runDialogue("BLACKSMITH_LEVEL_2")
  end,
  -- Northshore potions
  ["ECOLL " .. ET_NPC_4 .. " AREA 4 8"] = function(ent)
    Dialogues.runDialogue("POTIONS_MERCHANT")
  end,
  -- East screen of Northshore
  ["ECOLL " .. ET_NPC_2 .. " AREA 5 8"] = function(ent)
    Dialogues.runDialogue("ARCHITECT_HINT")
  end,
  -- Sign near Northshore pointing to the Desert
  ["ECOLL " .. ET_SIGN .. " AREA 2 9"] = function(ent)
    -- Show the sign text.
    Menu.showPopup("<= Desert")
  end,
  -- Area just south of Northshore with a broken bridge that gets fixed
  -- when the architect fixes the Highbridge bridge
  ["AREA 5 10"] = function()
    if Persister.getMainQuestState() >= MQS_RET_TO_HB then
      -- Fix the bridge by adding bridge tiles to fill the gap.
      Area.setTile(13, 6, TT_BRIDGE)
      Area.setTile(14, 6, TT_BRIDGE)
    end
  end,
  -- Clearing Lake area
  ["AREA 6 12"] = function()
    if Persister.getMainQuestState() >= MQS_RET_TO_HB then
      -- Fix the bridge by adding bridge tiles to fill the gap.
      Area.setTile(14, 7, TT_BRIDGE)
    end
  end,

  ------------------------------------------------------------------------------
  -- Eastport areas (World Map)
  ------------------------------------------------------------------------------
  -- Ship in Eastport
  ["ECOLL " .. ET_SHIP .. " AREA 7 10"] = function(ent)
    if Player.hasItem(IT_ASTROLABE) then
      Menu.show({
        text = "Do you want to sail to the Winter Lands?",
        options = { "No, stay here", "Yes, set sail!" },
        typewriter = true,
        callback = function(i)
          if i == 2 then
            Game.goToAreaG(105, 77)
            -- Final quest: go to the Lost Tower and defeat the Architect.
            Persister.setMainQuestState(MQS_TO_END)
          end
        end
      })
    else
      Menu.showPopup("To use the ship, you need to Astrolabe! Legends say it's hidden deep in the south-western Swamp.")
    end
  end,

  ------------------------------------------------------------------------------
  -- Tunnel areas
  ------------------------------------------------------------------------------
  -- Area transition from tunnel back to overworld (south exit)
  ["ATRAN 0 2 S"] = function()
    Game.goToAreaG(78, 135)
    return true  -- Block the normal transition
  end,
  -- Area transition from tunnel back to overworld (north exit)
  ["ATRAN 0 0 N"] = function()
    Game.goToAreaG(68, 128)
    -- The quest is now to go to the Northshore Mayor (if not yet done).
    Persister.setMainQuestState(MQS_TO_NS_MAYOR)
    return true  -- Block the normal transition
  end,

  ["ECOLL " .. ET_CHEST .. " AREA 0 2"] = function(ent)
    Chest.open(ent, IT_POTION, 1, "You found a healing potion! Press [B]/Shift to open your inventory and use it.")
  end,
  ["ECOLL " .. ET_CHEST .. " AREA 0 1"] = function(ent)
    Chest.open(ent, IT_TORCH)
  end,
  ["ECOLL " .. ET_CHEST .. " AREA 0 0"] = function(ent)
    Chest.open(ent, "GOLD", 20)
  end,

  ------------------------------------------------------------------------------
  -- Desert areas
  ------------------------------------------------------------------------------
  ["ECOLL " .. ET_NPC_1 .. " AREA 1 5"] = function(ent)
    Dialogues.runDialogue("OASIS")
  end,
  ["ECOLL " .. ET_NPC_2 .. " AREA 1 5"] = function(ent)
    Dialogues.runDialogue("TORCHMAKER")
  end,
  ["ECOLL " .. ET_NPC_4 .. " AREA 1 5"] = function(ent)
    Dialogues.runDialogue("ARCHITECT_HINT_OASIS")
  end,
  ["ECOLL " .. ET_NPC_ARCHITECT .. " AREA 1 4"] = function(ent)
    Dialogues.runDialogue("ARCHITECT")
  end,
  ["ECOLL " .. ET_CHEST .. " AREA 1 4"] = function(ent)
    Chest.open(ent, IT_TORCH, 2)
  end,
  -- Library 
  ["AREA 1 4"] = function()
    -- If the architect quest is complete, he's not here.
    if Persister.getMainQuestState() >= MQS_RET_TO_HB then
      Entities.deleteAllOfType(ET_NPC_ARCHITECT)
    end
  end,
  -- Exiting the library
  ["ATRAN 1 4 E"] = function()
    -- If the architect quest is complete, fast-travel to Highbridge
    if Persister.getMainQuestState() >= MQS_RET_TO_HB then
      Menu.show({
        text = "The architect has completed his work. Would you like to fast-travel to Highbridge?",
        options = { "Yes, fast-travel!" },
        callback = function(i)
          Game.goToAreaG(82, 159)
        end
      })
      return true -- override transition
    end
  end,
  -- Library cellar
  ["AREA 0 4"] = function()
    -- In this area there is an ET_BOOK entity that the player can pick up,
    -- but after they've picked it up, it should disappear.
    if Persister.getMainQuestState() ~= MQS_GET_BOOK then
      Entities.deleteAllOfType(ET_BOOK)
    end
  end,
  -- Pick up the book in the dark part of the library.
  ["ECOLL " .. ET_BOOK] = function(ent)
    -- Book in the dark part of the library.
    Menu.show({
      text = "You see a book called Bridgebuilding Unabridged.",
      options = { "Pick it up", "Leave it be" },
      typewriter = true,
      callback = function(i)
        if i ~= 1 then return end
        Entities.deleteAllOfType(ET_BOOK)
        Player.addItem(IT_BOOK)
        Triggers.handleGlobalTrigger("GOT_BOOK")
        Persister.setMainQuestState(MQS_RET_BOOK)
      end
    })
  end,
  ["GOT_BOOK"] = function()
    Sfx.play("SOLVE")
    Menu.showPopup("You picked up the book! Remember to deliver it to the Bridge Architect.")
  end,
  ["SPOKE_TO_ARCHITECT"] = function()
    -- Spoke to Architect in the desert: he vanishes (he went to Highbridge)
    Entities.deleteAllOfType(ET_NPC_ARCHITECT)
  end,

  ------------------------------------------------------------------------------
  -- Winter Lands
  ------------------------------------------------------------------------------
  -- Ship in Winter Lands
  ["ECOLL " .. ET_SHIP .. " AREA 6 6"] = function(ent)
    Menu.show({
      text = "Do you want to sail back to the continent?",
      options = { "No, stay here", "Yes, set sail!" },
      typewriter = true,
      callback = function(i)
        if i == 2 then
          Game.goToAreaG(119, 126)
        end
      end
    })
  end,
  -- Blacksmith in Winter Town
  ["ECOLL " .. ET_NPC_3 .. " AREA 6 3"] = function(ent)
    Dialogues.runDialogue("BLACKSMITH_LEVEL_3")
  end,
  -- Portions merchant in Winter Town
  ["ECOLL " .. ET_NPC_4 .. " AREA 6 3"] = function(ent)
    Dialogues.runDialogue("POTIONS_MERCHANT")
  end,
  -- Torchmaker in Winter Town
  ["ECOLL " .. ET_NPC_2 .. " AREA 6 3"] = function(ent)
    Dialogues.runDialogue("TORCHMAKER")
  end,
  -- Tower gate lever in area 5 1
  ["ECOLL " .. ET_LEVER .. " AREA 5 1"] = function(ent)
    Menu.show({
      text = "Pull the lever?",
      options = { "No, leave it", "Yes, pull it!" },
      callback = function(i)
        if i == 2 then
          -- Consume the lever so it becomes the "pulled lever" entity.
          Entities.consume(ent)
          -- Set the SSF_TOWER_GATE flag which will make us remove the gate
          -- when the user gets back to the tower.
          Persister.setFlag(SSF_TOWER_GATE)
          Menu.showPopup("The tower gate has opened! You can now enter the tower.")
        end
      end
    })
  end,
  ["AREA 6 0"] = function()
    -- If the tower gate is opened, consume the gate
    if Persister.hasFlag(SSF_TOWER_GATE) then
      Entities.consumeAllOfType(ET_GATE)
    end
  end,
  ["ECOLL " .. ET_NPC_1 .. " AREA 6 0"] = function(ent)
    Dialogues.runDialogue("TOWER_GATE_HINT")
  end,
  -- Area transition from Winter Lands tower area to Lost Tower
  ["ATRAN 6 0 N"] = function()
    Game.goToAreaG(19, 33)
    return true  -- Block the normal transition
  end,

  ------------------------------------------------------------------------------
  -- Lost Tower
  ------------------------------------------------------------------------------
  -- Area transition from Lost Tower to the outside
  ["ATRAN 1 2 S"] = function()
    Game.goToAreaG(104, 1)
    return true  -- Block the normal transition
  end,
  ["ECOLL " .. ET_DOOR_LOCKED .. " AREA 1 1"] = function(ent)
    if Player.hasItem(IT_KEY) then
      Menu.showPopup("To unlock the door, use the key from your inventory!")
    else 
      Menu.showPopup("The door is locked. You need to find a key!")
    end
  end,
  ["ECOLL " .. ET_CHEST .. " AREA 1 0"] = function(ent)
    -- Chest with the key.
    Chest.open(ent, IT_KEY, 1, "You found a key! It can open a locked door.")
  end,
  ["ECOLL " .. ET_CHEST .. " AREA 1 2"] = function(ent)
    -- Chest with 2 torches
    Chest.open(ent, IT_TORCH, 2)
  end,
  ["ECOLL " .. ET_CHEST .. " AREA 1 1"] = function(ent)
    -- Chest with a healing potion
    Chest.open(ent, IT_POTION)
  end,
  ["ECOLL " .. ET_CHEST .. " AREA 2 1"] = function(ent)
    -- Chest with 2 torches
    Chest.open(ent, IT_TORCH, 2)
  end,
  ["ECOLL " .. ET_CHEST .. " AREA 2 2"] = function(ent)
    -- Chest with a healing potion
    Chest.open(ent, IT_POTION)
  end,
  -- Entering the Final Boss room
  ["ATRAN 2 1 N"] = function()
    Game.goToAreaG(42, 10)
    return true  -- Block the normal transition
  end,
  -- Lever in AREA 2 2 (Lost Tower) to open final gate
  ["ECOLL " .. ET_LEVER .. " AREA 2 2"] = function(ent)
    Menu.show({
      text = "Pull the lever?",
      options = { "No, leave it", "Yes, pull it!" },
      callback = function(i)
        if i == 2 then
          -- Consume the lever so it becomes the "pulled lever" entity.
          Entities.consume(ent)
          -- Set the final gate flag
          Persister.setFlag(SSF_FINAL_GATE)
          Menu.showPopup("The gate to the top of the tower has opened!")
        end
      end
    })
  end,
  -- AREA 2 1 entry: consume gate entities if final gate is opened
  ["AREA 2 1"] = function()
    if Persister.hasFlag(SSF_FINAL_GATE) then
      Entities.consumeAllOfType(ET_GATE)
    end
  end,
  -- Final boss room
  ["ECOLL " .. ET_NPC_ARCHITECT .. " AREA 2 0"] = function()
    Dialogues.runDialogue("FINAL_BOSS")
  end,
  -- End of final boss dialogue - trigger final fight
  ["BOSS_BATTLE"] = function()
    Entities.deleteAllOfType(ET_NPC_ARCHITECT)
    Entities.deleteAllOfType(ET_FOUNTAIN)
    local unused0, unused1, mx, my = Area.globalMapToAreaTileCoords(40, 3)
    local wx, wz = Area.getTileWorldCenter(mx, my)
    Music.requestPlay("FINAL")
    Sfx.play("LIGHTNING")
    setRoomLighting("DIM")
    Game.setPendingAction(2, function()
      setRoomLighting("LIGHT")
      local bossEnt = Entities.create(ET_FINAL_BOSS, wx, wz, 180)
      bossEnt.thing:particles("puff", {scale=1.5, density=4, color="#00ff00"})
    end)
  end,
  ["EDEAD " .. ET_FINAL_BOSS] = function(ent)
    Music.requestStop()
    Sfx.play("SOLVE")
    Game.setPendingAction(90, function()
      Dialogues.runDialogue("VICTORY")
    end)
  end,
  ["VICTORY_RETURN"] = function()
    -- Go to "victory" version of Highbridge town
    Game.goToAreaG(53, 7)
  end,

  ------------------------------------------------------------------------------
  -- Highbridge (Victory version)
  ------------------------------------------------------------------------------
  ["ECOLL " .. ET_NPC_1 .. " AREA 3 0"] = function(ent)
    Menu.showPopup("The end! Thanks for playing!")
  end,
  ["ECOLL " .. ET_NPC_2 .. " AREA 3 0"] = function(ent)
    Menu.showPopup("The end! Thanks for playing!")
  end,
  ["ECOLL " .. ET_NPC_3 .. " AREA 3 0"] = function(ent)
    Menu.showPopup("The end! Thanks for playing!")
  end,
  ["ECOLL " .. ET_NPC_4 .. " AREA 3 0"] = function(ent)
    Menu.showPopup("The end! Thanks for playing!")
  end,
  ["ECOLL " .. ET_NPC_5 .. " AREA 3 0"] = function(ent)
    Menu.showPopup("The end! Thanks for playing!")
  end,
  ["ECOLL " .. ET_NPC_6 .. " AREA 3 0"] = function(ent)
    Menu.showPopup("The end! Thanks for playing!")
  end,
  ["ECOLL " .. ET_NPC_ARCHITECT .. " AREA 3 0"] = function(ent)
    Menu.showPopup("I'm back to my normal self! You saved me!")
  end,

  ------------------------------------------------------------------------------
  -- Entities in general
  ------------------------------------------------------------------------------
  -- Fire Bush
  ["ECOLL " .. ET_FIREBUSH] = function(ent)
    Player.addItem(IT_FIREFRUIT)
    -- Consume the entity (it will just disappear)
    Entities.consume(ent)
    -- Add puff particles effect
    ent.thing:particles("puff")
    Toast.showToast("Got +1 fire fruit")
    -- Ready to return to the Torch Maker?
    if Player.getItemCount(IT_FIREFRUIT) >= 5 then
      Persister.setMainQuestState(MQS_RET_TO_TORCHMAKER)
    end
  end,
  -- Lavenders
  ["ECOLL " .. ET_LAVENDER] = function(ent)
    Player.addItem(IT_LAVENDER)
    -- Consume the entity (it will just disappear)
    Entities.consume(ent)
    -- Add puff particles effect
    ent.thing:particles("puff")
    Toast.showToast("Got +1 lavender")
    if Player.getItemCount(IT_LAVENDER) >= 6 then
      -- Collected all lavenders?
      Persister.setMainQuestState(MQS_RET_TO_PERFUMER)
    end
  end,
  -- Fountains
  ["ECOLL " .. ET_FOUNTAIN] = function(ent) Fountain.interact(ent) end,
  -- Gold pieces
  ["ECOLL " .. ET_GOLD_PIECE] = function(ent)
    Player.addGold(1)
    Sfx.play("PICKUP")
    ent.thing:particles("puff")
    -- Remove the entity from the game
    ent.dead = true
    Toast.showToast("Got +1 gold")
  end,
  -- Gold piles
  ["ECOLL " .. ET_GOLD_PILE] = function(ent)
    Player.addGold(5)
    Sfx.play("PICKUP")
    ent.thing:particles("puff")
    Toast.showToast("Got +5 gold")
    -- Remove the entity from the game
    ent.dead = true
  end,
  -- Door
  ["ECOLL " .. ET_DOOR] = function(ent)
    Sfx.play("DOOR")
    ent.thing:particles("puff")
    ent.dead = true -- Mark for deletion
    -- Replace with ET_DOOR_OPEN entity
    Entities.create(ET_DOOR_OPEN, ent.x, ent.z)
    -- Brief effort state to simulate opening the door
    Player.startEffort(8)
  end,
  -- Unless otherwise specified, treasure chests grant 20 gold coins.
  ["ECOLL " .. ET_CHEST] = function(ent)
    Chest.open(ent, "GOLD", 20)
  end,
  -- Health well
  ["ECOLL " .. ET_WELL] = function(ent)
    Well.interact(ent, Well.doHealthWell)
  end,
  -- Got astrolabe
  ["IADD " .. IT_ASTROLABE] = function()
    -- The quest is now to return the astrolabe to the Highbridge mayor.
    Persister.setMainQuestState(MQS_ASTROLABE_TO_HB_MAYOR)
  end,

  -- Quest log
  ["QUEST_LOG"] = function()
    local s = Persister.getMainQuestState()
    local mqsInfo = QuestDesc.MQS_INFO[s]
    local desc = mqsInfo and mqsInfo.desc or "???"
    Menu.showPopup("CURRENT QUEST: " .. desc)
  end,
}

function _tryExitHighbridge(retDx, retDz)
  local s = Persister.getMainQuestState()
  -- If the player is supposed to talk to the Highbridge Mayor, don't let
  -- them leave without doing so.
  if s == MQS_TO_HB_MAYOR or s == MQS_PERFUME_TO_HB_MAYOR or
      s == MQS_RET_TO_HB or s == MQS_ASTROLABE_TO_HB_MAYOR then
    Menu.showPopup("Don't leave town without talking to the mayor first!")
    Player.x = Player.x + retDx
    Player.z = Player.z + retDz
    Player.vx, Player.vz = 0, 0
    return true
  end
end