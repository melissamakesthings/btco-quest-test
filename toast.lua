Toast={
  INITIAL_SCALE = 0.05,
  FINAL_SCALE = 0.15,
  ANIM_DURATION = 0.1,
  DURATION = 1,

  thing = getThing("Toast"),
  showing = false,

  -- If this is not nil, then this is the next message to show when
  -- the current toast ends.
  pendingMessage = nil,
}

-- Shows a toast with the given message. If a toast was already showing,
-- this toast will be shown right after. There's only a queue of 1, so
-- another one comes up when a message is showing and there's already one
-- in the queue, it will replace the one in the queue.
function Toast.showToast(message)
  if Toast.showing then
    -- Enqueue it.
    Toast.pendingMessage = message
    return
  end
  -- Show the toast.
  Toast.showing = true
  Utils.setLocalX(Toast.thing, 0)
  Toast.thing:setText(message)
  Toast.thing:setScale(Toast.INITIAL_SCALE)
  Toast.thing:startChangeScale(Toast.FINAL_SCALE, Toast.ANIM_DURATION)
  wait(Toast.DURATION, function()
    -- Hide toast
    Utils.setLocalX(Toast.thing, -99999)
    Toast.showing = false
    if Toast.pendingMessage then
      -- There's a toast pending, so show it now.
      local toShow = Toast.pendingMessage
      Toast.pendingMessage = nil
      Toast.showToast(toShow)
    end
  end)
end
