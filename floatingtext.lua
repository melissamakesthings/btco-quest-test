FloatingText = {
  showing = false,
  thing = getThing("FloatingText"),
  spinnerThing = getThing("FloatingTextSpin"),
}

-- Shows floating text with optional arguments
-- text (string) - The text to display (nil to hide)
-- style (string) - Optional style:
--   "transparent" - (default) transparent background
--   "opaque" - opaque background, large
--   "progress" - spinner + small opaque background
function FloatingText.show(text, style)
  style = style or "transparent"
  -- Passing nil is the same as calling hide.
  if not text then FloatingText.hide() return end
  FloatingText.showing = true
  FloatingText.thing:setText(text)
  Utils.setLocalX(FloatingText.thing, 0)
  FloatingText.thing:setFrame(
    style == "progress" and 3 or style == "opaque" and 2 or 1)
  Utils.setLocalX(FloatingText.spinnerThing, style == "progress" and 0 or -99999)
end

function FloatingText.hide()
  FloatingText.thing:setText("")
  Utils.setLocalX(FloatingText.thing, -99999)
  FloatingText.showing = false
end
