-- MENU SYSTEM

Menu = {
  MENU_POS_LX = 0,
  MENU_POS_LY = 3,
  MENU_POS_LZ = 44,
  MAX_BUTTONS = 4,
  TYPEWRITER_SPEED = 1,  -- Characters per update

  showing = false,
  callback = nil,
  optionValues = {},
  selIndex = 1,
  -- Until what time (as given by unixTime()) to ignore the user's intent to
  -- select an option, to avoid accidental selections.
  ignoreConfirmUntil = 0,
  
  -- Typewriter animation state
  textAnimActive = false,
  textAnimFullText = "",
  textAnimCurLength = 0,

  -- Time (as given by unixTime()) when the menu was last dismissed.
  dismissedTime = 0,
}

-- Shows a menu with the given parameters.
-- args: table with the following fields:
--   title: string, the title of the menu.
--   text: string, the message to display.
--   options: array, a list of options to display.
--     This can either be an array of strings, or an array of tables with
--     { text, value }, in which case the text is what's displayed and the value
--     is what's passed to the callback. If passed in array form, the value is
--     the index of the option (1-based).
--   callback: function to call when the user selects an option.
--     this will receive the selected value (1-based index or custom value).
--   bgImage: if passed, use this bg image for the menu. This can be the
--     special string "TRANSPARENT" to mean the menu text should be shown
--     over transparent background without an image.
--   typewriter: if true, the text will be shown with a typewriter effect.
--     If false, the text will be shown immediately.
--   offsetY: if not nil, this is added to the menu's Y position.
function Menu.show(args)
  if not Menu.bgOrigLx then
    Menu.bgOrigLx, Menu.bgOrigLy, Menu.bgOrigLz = getThing("MenuBackground"):getLocalPosition()
  end

  Menu.showing = true
  Sfx.play("OPEN")
  if args.title then
    getThing("MenuTitle"):setText(args.title)
    getThing("MenuTitle"):setFrame(1)  -- visible
  else
    getThing("MenuTitle"):setText("")
    getThing("MenuTitle"):setFrame(2)  -- invisible
  end
  
  -- Start typewriter animation, if requested
  if args.typewriter then
    Menu.textAnimFullText = args.text or ""
    Menu.textAnimCurLength = 0
    Menu.textAnimActive = true
    getThing("MenuText"):setText("")  -- Start with empty text
    -- Don't set ignoreConfirmUntil here - we'll set it when animation finishes
    Menu.ignoreConfirmUntil = 0
  else
    Menu.textAnimFullText = args.text or ""
    Menu.textAnimCurLength = #Menu.textAnimFullText  -- Show all text immediately
    Menu.textAnimActive = false  -- No animation, just show the full text
    getThing("MenuText"):setText(args.text or "") -- Show the full text immediately
    Menu.ignoreConfirmUntil = unixTime() + 0.5  -- Set ignore time to avoid accidental selections
  end
  -- If we're showing a BG image, use frame 2 that doesn't have the standard
  -- background so that the actual background shows through.
  getThing("MenuText"):setFrame(args.bgImage and 2 or 1)
  -- Show the menu background if a bg image was requested, otherwise hide it.
  getThing("MenuBackground"):setLocalPosition(
    args.bgImage and args.bgImage ~= "TRANSPARENT" and Menu.bgOrigLx or -10000,
    args.bgImage and args.bgImage ~= "TRANSPARENT" and Menu.bgOrigLy or -10000,
    args.bgImage and args.bgImage ~= "TRANSPARENT" and Menu.bgOrigLz or -10000
  )
  getThing("MenuBackground"):setMedia(
    args.bgImage and args.bgImage ~= "TRANSPARENT" and args.bgImage or nil)

  Menu.optionValues = {}
  local options = args.options or {}
  for i = 1, math.min(#options, Menu.MAX_BUTTONS) do
    local option = options[i]
    local optionText = type(option) == "table" and (option.text or "???") or option
    local optionValue = type(option) == "table" and option.value or i
    local button = getThing("MenuOption " .. i)
    button:setText(optionText)
    table.insert(Menu.optionValues, optionValue)
  end
  
  -- Hide all buttons initially while text is animating
  for i = 1, Menu.MAX_BUTTONS do
    local button = getThing("MenuOption " .. i)
    local x, y, z = button:getLocalPosition()
    button:setLocalPosition(100000, y, z)  -- Hide off-screen
  end
  
  Menu.selIndex = 1
  Menu.callback = args.callback
  
  -- Show the menu.
  getThing("Menu"):setLocalPosition(Menu.MENU_POS_LX,
    Menu.MENU_POS_LY + (args.offsetY or 0), Menu.MENU_POS_LZ)
  ButtonHints.hide()
  -- Show options immediately if not doing the typewriter effect.
  if not args.typewriter then Menu._showOptions() end
end

-- Convenience method for showing a simple popup message with an optional
-- callback when the user dismisses it.
function Menu.showPopup(message, callback)
  Menu.show({
    text = message,
    options = {},
    typewriter = true,
    callback = callback
  })
end

function Menu.update()
  if not Menu.showing then return end
  
  -- Handle typewriter animation
  if Menu.textAnimActive then
    -- Check if B button is being held to speed up animation
    local speedMultiplier = (input.b or input.a) and 4 or 1
    
    Menu.textAnimCurLength = Menu.textAnimCurLength + (Menu.TYPEWRITER_SPEED * speedMultiplier)
    
    if Menu.textAnimCurLength >= #Menu.textAnimFullText then
      -- Animation complete
      Menu.textAnimActive = false
      Menu.textAnimCurLength = #Menu.textAnimFullText
      getThing("MenuText"):setText(Menu.textAnimFullText)
      Menu._showOptions()
      -- Now set the ignore timer to avoid accidental selections
      Menu.ignoreConfirmUntil = unixTime() + 0.5
    else
      -- Show partial text
      local partialText = string.sub(Menu.textAnimFullText, 1, Menu.textAnimCurLength)
      getThing("MenuText"):setText(partialText)
    end
  end
end

function Menu._hide()
  if not Menu.showing then return end
  Menu.showing = false
  Menu.callback = nil
  Menu.optionValues = nil
  Menu.selIndex = nil
  Menu.textAnimActive = false
  Menu.textAnimFullText = ""
  Menu.textAnimCurLength = 0
  Menu.dismissedTime = unixTime()
  ButtonHints.hide()
  getThing("Menu"):setLocalPosition(0, 100000, 0)
end

function Menu._showOptions()
  -- Only show button hints if there are options to choose from
  if #Menu.optionValues > 0 then
    ButtonHints.show("Choose option")
  else
    ButtonHints.show("Continue")
  end
  
  -- Show only the buttons corresponding to the options that exist.
  for i = 1, Menu.MAX_BUTTONS do
    local button = getThing("MenuOption " .. i)
    local x, y, z = button:getLocalPosition()
    button:setLocalPosition(i <= #Menu.optionValues and 0 or 100000, y, z)
  end
  Menu._updateUi()
end

function Menu._updateUi()
  if not Menu.showing then return end
  
  for i = 1, Menu.MAX_BUTTONS do
    local button = getThing("MenuOption " .. i)
    if i == Menu.selIndex then
      button:setAnimation("loop", 4, 2, 3)
    else
      button:setFrame(0)
    end
  end
end

function Menu._handleButtonDownOptionless(buttonName)
  -- If there are no options and 'a' is pressed, dismiss the menu
  if buttonName == "a" and unixTime() > Menu.ignoreConfirmUntil then
    Sfx.play("CONFIRM")
    local cb = Menu.callback
    Menu._hide()
    if cb then cb(nil) end  -- Call callback with nil to indicate dismissal
    return true  -- Handled
  end
  
  -- For any other button when there are no options, just ignore
  return true  -- Handled (by ignoring)
end

function Menu.onButtonDown(buttonName)
  if not Menu.showing then return end
  
  -- Don't allow interaction while text is animating
  if Menu.textAnimActive then return end
  
  -- Handle the case where there are no options
  if #Menu.optionValues == 0 then
    Menu._handleButtonDownOptionless(buttonName)
    return
  end
  
  if buttonName == "down" then
    -- Increment Menu.selIndex by one with wrap-around (1-based).
    Menu.selIndex = (Menu.selIndex % #Menu.optionValues) + 1
    Sfx.play("SELECT")
    Menu._updateUi()
  elseif buttonName == "up" then
    -- Decrement Menu.selIndex by one with wrap-around (1-based).
    Menu.selIndex = (Menu.selIndex - 2 + #Menu.optionValues) % #Menu.optionValues + 1
    Sfx.play("SELECT")
    Menu._updateUi()
  elseif buttonName == "a" then
    if unixTime() <= Menu.ignoreConfirmUntil then
      -- Ignore the confirmation until the time has passed.
      return
    end
    -- User selected an option.
    Sfx.play("CONFIRM")
    local cb, val = Menu.callback, Menu.optionValues[Menu.selIndex]
    Menu._hide()
    if cb then cb(val) end
  end
end

function onMenuOptionClicked(msg)
  -- Don't allow interaction while text is animating
  if Menu.textAnimActive then return end
  
  local name = msg.name
  -- The name is of the form "MenuOption X" where X is the index (1-based).
  -- Extract the index using string.sub:
  local index = tonumber(string.sub(name, 12))
  if index then
    -- First show the option as being selected.
    Menu.selIndex = index
    Menu._updateUi()
    -- Then simulate button down for "a" to select the option.
    wait(0.1, function() onButtonDown("a") end)
  end
end
