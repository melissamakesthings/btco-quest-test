Chest = {}

-- ent: the chest entity
-- treasureType is an item type like IT_SWORD, or the special string "GOLD"
-- amount is the number of items or gold pieces to give. Default 1.
-- displayString is what to show to the player.
function Chest.open(ent, treasureType, amount, displayString)
  amount = amount or 1
  -- Show a menu confirming the player wants to open the chest
  Menu.show({
    title = "Chest",
    text = "Open the chest?",
    options = {"Leave it", "Open it"},
    callback = function(choice)
      if choice ~= 2 then return end
      -- Give them the item or treasure
      if treasureType == "GOLD" then
        Player.addGold(amount)
        Sfx.play("COIN")
        displayString = displayString or
          amount == 1 and "You found a gold piece!" or
          ("You found " .. amount .. " gold pieces!")
      else
        local info = Items.getInfo(treasureType)
        if not info then
          error("Invalid treasure type: " .. tostring(treasureType))
          return
        end
        Player.addItem(treasureType, amount)
        Sfx.play("PICKUP")
        displayString = displayString or
          (amount == 1 and ("Found:\n\n" .. info.name) or
          ("Found:\n\n " .. amount .. " x " .. info.name))
      end
      
      -- Show the treasure description to the player
      Menu.showPopup(displayString)
      
      -- Consume the chest (this will replace it with ET_CHEST_OPEN)
      Entities.consume(ent)
    end
  })
end