InventoryUi = {
  -- Inventory grid size. This must correspond to IT_MAX, so we require that:
  --   GRID_WIDTH * GRID_HEIGHT = IT_MAX.
  GRID_WIDTH = 4, GRID_HEIGHT = 4,

  -- If true we are showing the inventory UI.
  showing = false,
  -- Currently selected item index in the inventory. This is 1-based.
  curSel = 1,
  -- Time (as given by unixTime()) when the inventory UI was last dismissed.
  dismissedTime = 0,
}

-- Shows the inventory UI.
function InventoryUi.show()
  if InventoryUi.showing then return end
  InventoryUi.showing = true
  Sfx.play("OPEN")
  InventoryUi.updateUi()
  -- Bring it to the center to show it.
  Utils.setLocalX(getThing("Inventory"), 0)
  -- Show the player's gold
  getThing("InvGold"):setText(tostring(Player.gold))
  ButtonHints.show("Use Item", "Close Inventory")
end

function InventoryUi.hide()
  if not InventoryUi.showing then return end
  InventoryUi.showing = false
  Sfx.play("CLOSE")
  -- Hide the inventory UI by moving it out of view.
  Utils.setLocalX(getThing("Inventory"), -99999)
  ButtonHints.hide()
end

-- Reminder: buttonName can be "up", "down", "left", "right", "a" or "b".
function InventoryUi.onButtonDown(buttonName)
  if not InventoryUi.showing then return end
  
  -- Convert 1-based index to grid coordinates (0-based for calculation)
  local row = math.floor((InventoryUi.curSel - 1) / InventoryUi.GRID_WIDTH)
  local col = (InventoryUi.curSel - 1) % InventoryUi.GRID_WIDTH
  
  -- Handle navigation
  if buttonName == "up" then
    row = row - 1
    if row < 0 then row = InventoryUi.GRID_HEIGHT - 1 end  -- wrap to bottom
    Sfx.play("SELECT")
  elseif buttonName == "down" then
    row = row + 1
    if row >= InventoryUi.GRID_HEIGHT then row = 0 end  -- wrap to top
    Sfx.play("SELECT")
  elseif buttonName == "left" then
    col = col - 1
    if col < 0 then col = InventoryUi.GRID_WIDTH - 1 end  -- wrap to right
    Sfx.play("SELECT")
  elseif buttonName == "right" then
    col = col + 1
    if col >= InventoryUi.GRID_WIDTH then col = 0 end  -- wrap to left
    Sfx.play("SELECT")
  elseif buttonName == "a" then
    InventoryUi._useItem()
  elseif buttonName == "b" then
    InventoryUi.hide()  -- Hide the inventory UI
    InventoryUi.dismissedTime = unixTime()
    return  -- No further action needed
  end
  
  -- Convert back to 1-based index
  InventoryUi.curSel = row * InventoryUi.GRID_WIDTH + col + 1
  
  -- Update the UI to reflect the new selection
  InventoryUi.updateUi()
end

-- Helper function to use the currently selected item
function InventoryUi._useItem()
  local selectedItemCount = Player.inventory[InventoryUi.curSel] or 0
  if selectedItemCount <= 0 then return end
  
  local itemInfo = Items.ITEM_INFO[InventoryUi.curSel]
  if not itemInfo or not itemInfo.useFun then return end
  
  -- Item has a use function. First play confirm sound, hide the inventory UI, then call it.
  Sfx.play("CONFIRM")
  InventoryUi.hide()
  itemInfo.useFun()
end

-- Updates the UI to reflect the current state.
function InventoryUi.updateUi()
  if not InventoryUi.showing then return end
  
  -- Update the title to show the currently selected item name
  local selectedItemCount = Player.inventory[InventoryUi.curSel] or 0
  local titleText = ""
  if selectedItemCount > 0 then
    local itemInfo = Items.ITEM_INFO[InventoryUi.curSel]
    if itemInfo and itemInfo.name then
      local quality = Player.getItemQuality(InventoryUi.curSel)
      if quality > 0 then
        titleText = "+" .. quality .. " " .. itemInfo.name
      else
        titleText = itemInfo.name
      end
    end
  end
  getThing("InvSlotTitle"):setText(titleText)
  
  for i = 1, IT_MAX do
    local itemCount = Player.inventory[i] or 0
    local itemThing = getThing("ItemIcon " .. i)
    if itemCount > 0 then
      itemThing:setText(itemCount > 1 and tostring(itemCount) or "")
      itemThing:setFrame(i)  -- show the item
      Utils.setLocalX(itemThing, 0)  -- show
    else
      itemThing:setText("")
      itemThing:setFrame(1)
      Utils.setLocalX(itemThing, -99999)  -- hide
    end
    if i == InventoryUi.curSel then
      getThing("InventorySlot " .. i):setAnimation("loop", 4, 2, 3)  -- selected
    else
      getThing("InventorySlot " .. i):setFrame(1)  -- unselected
    end
  end
end
