-- BUTTONS HINT UI
-- This shows at the bottom of the screen to remind the player
-- which buttons do what.

ButtonHints = {
  showing = false,
  aButtonHint = "",
  bButtonHint = "",
}

function ButtonHints.show(aButtonHint, bButtonHint)
  if (ButtonHints.showing and
      ButtonHints.aButtonHint == aButtonHint and
      ButtonHints.bButtonHint == bButtonHint) then
    return  -- No change, no need to update
  end
  ButtonHints.showing = true
  ButtonHints.aButtonHint = aButtonHint
  ButtonHints.bButtonHint = bButtonHint
  -- Show the panel.
  Utils.setLocalX(getThing("ButtonHints"), 0)  -- Adjust as needed for your layout
  Utils.setLocalX(getThing("ButtonHint 1"), aButtonHint and 0 or -99999)
  Utils.setLocalX(getThing("ButtonHint 2"), bButtonHint and 0 or -99999)
  getThing("ButtonHint 1"):setText(aButtonHint or "")
  getThing("ButtonHint 2"):setText(bButtonHint or "")
end

function ButtonHints.hide()
  ButtonHints.showing = false
  -- Hide the panel.
  Utils.setLocalX(getThing("ButtonHints"), -99999)
  Utils.setLocalX(getThing("ButtonHint 1"), -99999)
  Utils.setLocalX(getThing("ButtonHint 2"), -99999)
end
