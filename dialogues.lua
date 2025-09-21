-- DIALOGUES
--
-- A Dialogue is a table where each key is a dialogue state name (always
-- in ALL CAPS) and the values are DialogueState.
--
-- DialogueState is an array with the following structure:
-- { message, option1, option2, ... }
--
-- The message and options are tables of type DialogueItem.
--
-- DialogueItem is a table with these fields:
--   t: (string) the text to display
--   go: (string) if present in a response, goes to this state when selected.
--   trigger: (string) if present in a response, triggers the given global trigger.
--     If present in the message, triggers when the state is entered.
--   iff: (string) if present in a response, only shows the response if this
--     savestate flag (SSF) is set.
--   ifi: (number or table) if present in a response, only shows the response if 
--     the player has the required item(s). Can be:
--     - A single item type (e.g., IT_SWORD) to check for at least 1
--     - A table {itemType, count} (e.g., {IT_FIREFRUIT, 10}) to check for at least count
--     Examples:
--       {ifi=IT_SWORD, t="[Use sword] Attack!", go="ATTACK"}
--       {ifi={IT_FIREFRUIT,10}, t="[Give 10 Fire Fruit] Here you go.", go="GIVE"}
--   ifiq: (number) if present in a response, only shows the response if the 
--     item quality is >= the specified value. Must be used with "quality" field.
--     Example:
--       {ifiq=IT_SWORD, quality=1, t="Already upgraded!", go="ALREADY"}
--   ifmqs: (number) if present in a response, only shows the response if the
--     main quest state is >= the specified value.
--     Example:
--       {ifmqs=3, t="Quest progress option", go="QUEST_OPTION"}
--   add: (number or table) if present, adds item(s) to the player when the option
--     is selected (for responses) or when the state is entered (for messages).
--     Uses the same syntax as ifi:
--     - A single item type (e.g., IT_SWORD) to add 1 item
--     - A table {itemType, count} (e.g., {IT_POTION, 3}) to add count items
--     Examples:
--       {add=IT_SWORD, t="You receive a sword!", go="NEXT"}
--       {add={IT_POTION,3}, t="Take these potions.", go="THANKS"}
--   remove: (number or table) if present, removes item(s) from the player when the option
--     is selected (for responses) or when the state is entered (for messages).
--     Uses the same syntax as ifi and add:
--     - A single item type (e.g., IT_SWORD) to remove 1 item
--     - A table {itemType, count} (e.g., {IT_FIREFRUIT, 10}) to remove count items
--     Examples:
--       {remove=IT_SWORD, t="You hand over your sword.", go="NEXT"}
--       {remove={IT_FIREFRUIT,10}, t="You give 10 fire fruits.", go="THANKS"}
--   setf: (string) if present in a response, sets the given savestate flag
--     when the response is selected. If present in the message, sets the flag
--     when the state is entered.
--   setmqs: (number) if present in a response, sets the main quest state to the
--     given number when the response is selected. If present in the message, 
--     sets the main quest state when the state is entered.
--   auto: (boolean) if present in the message, this state will not be shown
--     to the user, but will automatically advance to the first valid response
--     (that is the first one that's not gated by an "if"). This is useful
--     to go to a given state depending on the flags.
--   pay: (number) if present in a response, the player must pay this
--     amount of gold to select the response. If the player doesn't have enough
--     gold, selecting the response displays "You don't have enough gold!" and
--     does not advance the dialogue.
--   max: (number) if present in a response with "add", prevents adding items
--     if the player already has this many of the item. Displays "You already 
--     have X, can't carry more." and does not advance the dialogue.
--     Example:
--       {pay=5, add=IT_POTION, max=6, t="Buy potion", go="BOUGHT"}
--   upgrade: (number) if present in a response, upgrades the given item to the 
--     specified quality level. Must be used with "quality" field.
--     Example:
--       {pay=50, upgrade=IT_SWORD, quality=1, t="Upgrade sword", go="UPGRADED"}
--   quality: (number) specifies the quality level for "ifiq" and "upgrade" actions.
--
-- The dialogue always start in the START state.

Dialogues = {
  -- Current dialogue being run.
  curDialogueId = nil,

  DIALOGUE_ITEM_SPEC = {
    t="string?",
    go="string?",
    trigger="string?",
    iff="string?",
    ifi="number|table?",
    ifiq="number?",
    ifmqsEQ="number?",
    ifmqsLE="number?",
    ifmqsGE="number?",
    ifmqsLT="number?",
    ifmqsGT="number?",
    add="number|table?",
    remove="number|table?",
    setf="string?",
    setmqs="number?",
    auto="boolean?",
    pay="number?",
    max="number?",
    upgrade="number?",
    quality="number?",
  },
}

-- Runs the given dialog.
-- Note that this can be called even while in a dialogue in order to "chain"
-- one dialogue into the other.
function Dialogues.runDialogue(dialogueId) 
  if not dialogueId then error("Dialogues.runDialogue: dialogueId is required") end
  if not ALL_DIALOGUES[dialogueId] then
    error("Dialogues.runDialogue: dialogue not found: " .. dialogueId)
  end
  
  -- Validate the entire dialogue structure
  Dialogues._validateDialogue(ALL_DIALOGUES[dialogueId], dialogueId)
  
  -- Play dialogue sound effect when starting a new dialogue
  Sfx.play("DIALOGUE")
  
  Dialogues.curDialogueId = dialogueId
  Dialogues._startDialogue(ALL_DIALOGUES[dialogueId], "START")
end

-- Validates an entire dialogue structure
function Dialogues._validateDialogue(dialogue, dialogueId)
  if type(dialogue) ~= "table" then
    error("Dialogue " .. dialogueId .. " must be a table")
  end
  for stateName, dialogueState in pairs(dialogue) do
    -- Only keys in UPPERCASE are dialogue states (there might be other keys).
    if stateName:upper() == stateName then
      -- Validate the message and options (all DialogueItems)
      for i = 1, #dialogueState do
        local option = dialogueState[i]
        Utils.validate(option, Dialogues.DIALOGUE_ITEM_SPEC,
          "dialogue:" .. dialogueId .. "." .. stateName .. "#" .. i)
      end
    end
  end
end

-- Internal function to start or continue a dialogue from a given state
function Dialogues._startDialogue(dialogue, currentState)
  if not currentState then
    Dialogues.curDialogueId = nil
    return -- End dialogue
  end
  
  local dialogueState = dialogue[currentState]
  if not dialogueState then
    error("Dialogue state not found: " .. currentState)
    return
  end
  
  -- Process the current dialogue state
  Dialogues._processDialogueState(dialogue, dialogueState)
end

-- Processes a single dialogue state
function Dialogues._processDialogueState(dialogue, dialogueState)
  if not dialogueState or #dialogueState == 0 then
    return -- End dialogue
  end
  
  local messageItem = dialogueState[1]
  local options = {}
  
  -- Extract options from the dialogue state (everything after the first item)
  for i = 2, #dialogueState do
    local option = dialogueState[i]
    table.insert(options, option)
  end
  
  -- Check if this is an auto state
  if messageItem.auto then
    local nextState = Dialogues._handleAutoState(options)
    Dialogues._startDialogue(dialogue, nextState)
    return
  end
  
  -- Process message item triggers and flags
  if messageItem.trigger then Triggers.handleGlobalTrigger(messageItem.trigger) end
  if messageItem.setf then Persister.setFlag(messageItem.setf) end
  if messageItem.setmqs then Persister.setMainQuestState(messageItem.setmqs) end
  if messageItem.add then Dialogues._addItems(messageItem.add) end
  if messageItem.remove then Dialogues._removeItems(messageItem.remove) end
  -- If no options, this ends the dialogue
  if #options == 0 then return end
  
  -- Filter valid options based on conditions
  local validOptions = Dialogues._filterValidOptions(options)
  if #validOptions == 0 then return end
  
  -- Show the dialogue menu and wait for user selection
  Dialogues._showDialogueMenu(dialogue, messageItem.t or "", validOptions)
end

-- Handles auto states that automatically advance to the first valid response
function Dialogues._handleAutoState(options)
  for _, option in ipairs(options) do
    if Dialogues._isOptionValid(option) then
      return Dialogues._executeOption(option)
    end
  end
  return nil -- No valid options found
end

-- Filters options to only include those that meet their conditions
function Dialogues._filterValidOptions(options)
  local validOptions = {}
  
  for _, option in ipairs(options) do
    if Dialogues._isOptionValid(option) then
      table.insert(validOptions, option)
    end
  end
  
  return validOptions
end

-- Checks if an option is valid based on its conditions
function Dialogues._isOptionValid(option)
  -- Check if the option has an "iff" condition (flag-based)
  if option.iff then
    return Persister.hasFlag(option.iff)
  end
  
  -- Check if the option has an "ifi" condition (item-based)
  if option.ifi then
    return Dialogues._checkItemCondition(option.ifi)
  end
  
  -- Check if the option has an "ifiq" condition (item quality-based)
  if option.ifiq then
    return Dialogues._checkItemQualityCondition(option.ifiq, option.quality)
  end
  
  -- Check if the option has an "ifmqs" condition (main quest state-based)
  if option.ifmqsEQ then
    return Persister.getMainQuestState() == option.ifmqsEQ
  elseif option.ifmqsLT then
    return Persister.getMainQuestState() < option.ifmqsLT
  elseif option.ifmqsGT then
    return Persister.getMainQuestState() > option.ifmqsGT
  elseif option.ifmqsGE then
    return Persister.getMainQuestState() >= option.ifmqsGE
  elseif option.ifmqsLE then
    return Persister.getMainQuestState() <= option.ifmqsLE
  end
  
  -- Note: We don't check "pay" conditions here because we want to show
  -- payment options even if the player can't afford them. The payment
  -- validation happens when the option is selected.
  
  return true -- No conditions, so it's valid
end

-- Checks if the player meets the item condition
-- ifi can be:
--   - A single item type (e.g., IT_SWORD) - checks for at least 1
--   - A table {itemType, count} (e.g., {IT_FIREFRUIT, 10}) - checks for at least count
function Dialogues._checkItemCondition(ifi)
  local itemType, count = Dialogues._parseItemSpec(ifi)
  return Player.getItemCount(itemType) >= count
end

-- Checks if the player meets the item quality condition
-- ifiq should be the item type, quality should be the required quality level
function Dialogues._checkItemQualityCondition(itemType, requiredQuality)
  if type(itemType) ~= "number" then
    error("Invalid item quality condition: ifiq should be an item type")
  end
  if type(requiredQuality) ~= "number" then
    error("Invalid item quality condition: quality field is required and should be a number")
  end
  return Player.getItemQuality(itemType) >= requiredQuality
end

-- Parses an item specification and returns itemType, count
-- itemSpec can be:
--   - A single item type (number) - returns itemType, 1
--   - A table {itemType, count} - returns itemType, count
function Dialogues._parseItemSpec(itemSpec)
  if type(itemSpec) == "number" then
    -- Single item type, default count is 1
    return itemSpec, 1
  elseif type(itemSpec) == "table" and #itemSpec == 2 then
    -- Table with {itemType, count}
    return itemSpec[1], itemSpec[2]
  else
    error("Invalid item specification format: " .. tostring(itemSpec))
  end
end

-- Adds items to the player based on the item specification
-- itemSpec uses the same format as ifi (single item or {itemType, count})
function Dialogues._addItems(itemSpec)
  local itemType, count = Dialogues._parseItemSpec(itemSpec)
  Player.addItem(itemType, count)
end

-- Removes items from the player based on the item specification
-- itemSpec uses the same format as ifi (single item or {itemType, count})
function Dialogues._removeItems(itemSpec)
  local itemType, count = Dialogues._parseItemSpec(itemSpec)
  Player.removeItem(itemType, count)
end

-- Upgrades an item to the specified quality level
-- itemType should be the item type, quality should be the target quality level
function Dialogues._upgradeItem(itemType, quality)
  if type(itemType) ~= "number" then
    error("Invalid upgrade specification: upgrade should be an item type")
  end
  if type(quality) ~= "number" then
    error("Invalid upgrade specification: quality field is required and should be a number")
  end
  Player.setItemQuality(itemType, quality)
  Sfx.play("UPGRADE")
end

-- Handles maximum item validation for an option
-- Returns true if the option can proceed, false if max limit reached
function Dialogues._validateMaxItems(option, dialogue, message, options)
  if not option.max or not option.add then
    return true -- No max limit or no items being added
  end
  
  local itemType, count = Dialogues._parseItemSpec(option.add)
  local currentCount = Player.getItemCount(itemType)
  
  if currentCount >= option.max then
    -- Show "max reached" message and return to same dialogue state
    Menu.show({
      title = dialogue.title,
      text = "You already have " .. option.max .. ", can't carry more.",
      options = {"OK"},
      typewriter = true,
      callback = function()
        Dialogues._showDialogueMenu(dialogue, message, options)
      end
    })
    return false
  end
  
  return true
end

-- Handles payment validation for an option
-- Returns true if the option can proceed, false if payment failed
function Dialogues._validatePayment(option, dialogue, message, options)
  if not option.pay then
    return true -- No payment required
  end
  
  if Player.hasGold(option.pay) then
    return true -- Player has enough gold
  end
  
  -- Show "not enough gold" message and return to same dialogue state
  Menu.show({
    title = dialogue.title,
    text = "You don't have enough gold!",
    options = {"OK"},
    typewriter = true,
    callback = function()
      Dialogues._showDialogueMenu(dialogue, message, options)
    end
  })
  return false
end

-- Shows the dialogue menu and waits for user selection
function Dialogues._showDialogueMenu(dialogue, message, options)
  -- Prepare menu options for display
  local menuOptions = {}
  
  for _, option in ipairs(options) do
    table.insert(menuOptions, option.t or "???")
  end
  
  -- Show the menu and wait for selection
  Menu.show({
    title = dialogue.title,  -- can be nil
    text = message,
    options = menuOptions,
    typewriter = true,
    callback = function(selectedIndex)
      local selectedOption = options[selectedIndex]
      
      -- Validate payment requirement
      if not Dialogues._validatePayment(selectedOption, dialogue, message, options) then
        return -- Payment failed, don't proceed
      end
      
      -- Validate max items requirement
      if not Dialogues._validateMaxItems(selectedOption, dialogue, message, options) then
        return -- Max items reached, don't proceed
      end
      
      local nextState = Dialogues._executeOption(selectedOption)
      Dialogues._startDialogue(dialogue, nextState)
    end
  })
end

-- Executes an option and returns the next state
function Dialogues._executeOption(option)
  -- Handle payment
  if option.pay then
    Player.removeGold(option.pay)
  end
  
  -- Handle flag setting
  if option.setf then
    Persister.setFlag(option.setf)
  end
  
  -- Handle main quest state setting
  if option.setmqs then
    Persister.setMainQuestState(option.setmqs)
  end
  
  -- Handle item adding
  if option.add then
    Dialogues._addItems(option.add)
  end
  
  -- Handle item removing
  if option.remove then
    Dialogues._removeItems(option.remove)
  end
  
  -- Handle item upgrading
  if option.upgrade then
    Dialogues._upgradeItem(option.upgrade, option.quality)
  end
  
  -- Handle trigger execution
  if option.trigger then
    Triggers.handleGlobalTrigger(option.trigger)
  end
  
  -- Determine next state
  return option.go  -- either the state, or nil to end the dialogue
end
