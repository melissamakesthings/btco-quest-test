Cutscene = {
  -- If true, a cutscene is playing.
  active = false,
  -- Array of actions for the cutscene.
  -- Each action can be a function to execute or a number to indicate a wait
  -- time in seconds. It can also be of the form { function, arg1, arg2, ... }
  -- to call a function with arguments.
  actions = {},
  -- Next action index to execute.
  nextActionIndex = 1,
}

function Cutscene.start(actions)
  -- NOTE: we allow starting a cutscene even if one is already active
  -- if we're at the end of the current cutscene. This allows them to be
  -- chained together.
  if Cutscene.active and Cutscene.nextActionIndex <= #Cutscene.actions then
    error("Cutscene already active, cannot start a new one.")
    return
  end
  Cutscene.active = true
  Cutscene.actions = actions or {}
  Cutscene.nextActionIndex = 1
  Cutscene.executeNextAction()
end

function Cutscene.executeNextAction()
  if not Cutscene.active or Cutscene.nextActionIndex > #Cutscene.actions then
    -- End of cutscene.
    Cutscene.active = false
    -- Restore camera follow behavior, in case the cutscene changed it.
    Camera.setFollowPlayer(true)
    return
  end
  
  local action = Cutscene.actions[Cutscene.nextActionIndex]
  Cutscene.nextActionIndex = Cutscene.nextActionIndex + 1

  -- If the action is a function, execute it.
  if action and type(action) == "function" then
    action()
    Cutscene.executeNextAction()  -- Immediately execute the next action
  elseif type(action) == "number" then
    -- Wait for the specified number of seconds, then execute the next action.
    wait(action, Cutscene.executeNextAction)
  elseif type(action) == "table" and type(action[1]) == "function" then
    (action[1])(table.unpack(action, 2))  -- Call the function with additional arguments
  else
    error("Invalid action type in cutscene: " .. tostring(action))
  end
end

