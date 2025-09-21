Items = {
  -- See ITEM_INFO at end of file.
}

function Items.useTorch()
  if Area.lighting == "BRIGHT" then
    Menu.showPopup("No need for a torch here! It's already bright enough.")
    return
  end
  Menu.show({
    title = "Use Torch",
    text = "Light the torch?",
    options = {"No", "Yes"},
    callback = function(choice)
      if choice == 2 then
        Player.removeItem(IT_TORCH)
        Player.lightTorch()
      end
    end
  })
end

function Items.usePerfume()
  Menu.show({
    title = "Use Perfume",
    text = "Use the perfume?",
    options = {"No", "Yes"},
    callback = function(choice)
      if choice == 2 then
        -- NOTE: the perfume isn't consumed (the player has
        -- an infinite supply of it).
        Player.applyPerfume()
        Menu.showPopup("You are now immune from the stinky swamp effects.")
      end
    end
  })
end

function Items.useHealingPotion()
  Menu.show({
    title = "Use Healing Potion",
    text = "Drink the healing potion?",
    options = {"No", "Yes"},
    callback = function(choice)
      if choice == 2 then
        Player.removeItem(IT_POTION)
        Player.healFully()
        Sfx.play("HEAL")
        Player.thing:particles("puff", {color="#ff6060"})
      end
    end
  })
end

function Items.useKey()
  -- Check if the player is near a locked door
  local lockedDoor = Entities.getEntInCircle(
    Player.x, Player.z, TILE_SIZE, ER_SOLID)
  
  -- Check if the found entity is actually a locked door
  if not lockedDoor or lockedDoor.etype ~= ET_DOOR_LOCKED then
    Menu.showPopup("There are no locked doors nearby.")
    return
  end

  Menu.show({
    title = "Use Key",
    text = "Unlock the door?",
    options = {"No", "Yes"},
    callback = function(choice)
      if choice == 2 then
        Player.removeItem(IT_KEY)
        lockedDoor.thing:particles("puff")
        Sfx.play("SOLVE")
        -- Consume the locked door (this will replace it with ET_DOOR_OPEN)
        Entities.consume(lockedDoor)
      end
    end
  })
end

function Items.useMap()
  local aconfig = Area.getAreaConfig() or {}
  if aconfig.noMap then
    Menu.showPopup("Can't use the map here.")
    return
  end
  wait(0.1, function() WorldMap.show() end)
end

function Items.getInfo(itemType)
  if not itemType or type(itemType) ~= "number" then return nil end
  return Items.ITEM_INFO[itemType]
end

function Items.useQuestLog()
  Triggers.handleGlobalTrigger("QUEST_LOG")
end

Items.ITEM_INFO = {
  [IT_SWORD] = { name = "Sword" },
  [IT_QUESTLOG] = { name = "Quest Log", useFun = Items.useQuestLog },
  [IT_POTION] = { name = "Healing Potion", useFun = Items.useHealingPotion },
  [IT_TORCH] = { name = "Torch", useFun = Items.useTorch },
  [IT_FIREFRUIT] = { name = "Fire Fruit" },
  [IT_KEY] = { name = "Key", useFun = Items.useKey },
  [IT_BOOK] = { name = "Book" },
  [IT_PERFUME] = { name = "Perfume", useFun = Items.usePerfume },
  [IT_LAVENDER] = { name = "Lavender" },
  [IT_ASTROLABE] = { name = "Astrolabe" },
  [IT_MAP] = { name = "World Map", useFun = Items.useMap },
}
