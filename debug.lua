Debug = {
  buttonPressCount = 0,
}

function Debug.maybeShowDebugPrompt()
  -- si cubiculum meum est et InventoryUi ostenditur et clave "supra" detenta
  -- ter "sinistra" pressero, "DEBUG COMMAND" ostendetur
  if isOwnRoom() and InventoryUi.showing and input.up and input.leftJustPressed then
    Debug.buttonPressCount = Debug.buttonPressCount + 1
    if Debug.buttonPressCount >= 3 then
      Debug.buttonPressCount = 0
      prompt("DEBUG COMMAND", Debug._runCommand);
    end
  end
end

function Debug._runCommand(command)
  local player = Player.thing
  local parts = split(command, " ")
  InventoryUi.hide()
  if parts[1] == "ubi" then
    print("hic sum: " .. Area.areaX .. " " .. Area.areaY .. " " .. round(Player.x) .. " " .. round(Player.z))
  elseif parts[1] == "i" then
    -- Si #parts == 5, sunt areaX, areaY, px, pz
    -- Si #parts == 3, sunt gx, gy
    if #parts == 5 then
      local areaX, areaY, px, pz = tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4]), tonumber(parts[5])
      Game.goToArea(areaX, areaY, px, pz)
    elseif #parts == 3 then
      local gx, gy = tonumber(parts[2]), tonumber(parts[3])
      if gx and gy then
        Game.goToAreaG(gx, gy)
      else
        player:say("Nescio quo ire opus sit")
      end
    else
      player:say("Nescio quo eundum sit")
    end
  elseif parts[1] == "celer" then
    player:say("Celeriter ambulabo")
    Player.ACCEL, Player.MAX_SPEED = 4, 4
  elseif parts[1] == "fons" then
    Fountain.interact()
  elseif parts[1] == "sume" and #parts >= 2 then
    local itemId = tonumber(parts[2])
    local quantity = tonumber(parts[3]) or 1
    if itemId and itemId >= 1 and itemId <= IT_MAX then
      Player.addItem(itemId, quantity)
      player:say("Accepi rem " .. itemId .. " x" .. quantity)
    else
      player:say("Nescio quid sit")
    end
  elseif parts[1] == "depone" and #parts >= 2 then
    local itemId = tonumber(parts[2])
    local quantity = tonumber(parts[3]) or 1
    if itemId and itemId >= 1 and itemId <= IT_MAX then
      if Player.removeItem(itemId, quantity) then
        player:say("Deposui rem " .. itemId .. " x" .. quantity)
      else
        player:say("Non satis habeo")
      end
    else
      player:say("Nescio quid sit")
    end
  elseif parts[1] == "vexilla" then
    player:say(Persister.saveState[PSF_QUESTF] or "nil")
  elseif parts[1] == "aurum" and #parts >= 2 then
    local amount = tonumber(parts[2])
    if amount and amount > 0 then
      Player.addGold(amount)
      player:say("Accepi " .. amount .. " nummos")
    else
      player:say("Nescio quot")
    end
  elseif parts[1] == "mqs" then
    if #parts == 1 then
      -- No arguments: print current main quest state
      local currentState = Persister.getMainQuestState()
      player:say("MQS est " .. (currentState or "nil"))
    elseif #parts == 2 then
      -- One argument: set main quest state
      local newState = tonumber(parts[2])
      if newState then
        local oldState = Persister.getMainQuestState()
        Persister.setMainQuestState(newState, true)
        player:say("MQS erat " .. oldState .. ", factum est " .. newState)
      else
        player:say("Non numerus esse videtur")
      end
    else
      player:say("Nimia argumenta")
    end
  else
    player:say("Nescio quid tibi velis")
  end
end
