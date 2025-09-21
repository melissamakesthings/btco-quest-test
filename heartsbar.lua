HeartsBar = {
  showing = false,
  MAX_HEARTS = 8,

  -- The hpMax and hp values that we are currently displaying.
  hpMax = -1,
  hp = -1,
}

function HeartsBar.show()
  HeartsBar.showing = true
  Utils.setLocalX(getThing("HeartsBar"), 0) -- show
  HeartsBar.updateIfNeeded()
end

function HeartsBar.hide()
  HeartsBar.showing = false
  Utils.setLocalX(getThing("HeartsBar"), -10000) -- hide
end

-- Updates the display of the hearts bar based on Player's current HP.
-- This is cheap to call frequently, as it only updates if the HP has changed.
function HeartsBar.updateIfNeeded()
  if Player.hpMax == HeartsBar.hpMax and Player.hp == HeartsBar.hp then
    return  -- No change, no need to update
  end
  HeartsBar.hpMax = Player.hpMax
  HeartsBar.hp = Player.hp

  -- The heart containers are called "Heart N" for N = 1 to HeartsBar.MAX_HEARTS.
  -- We want to show the first Player.hpMax hearts and hide the remaining ones.
  for i = 1, HeartsBar.MAX_HEARTS do
    local heart = getThing("Heart " .. i)
    
    if i <= Player.hpMax then
      -- Show this heart container
      Utils.setLocalY(heart, 0)  -- Make visible
      
      -- Set frame based on current HP
      if i <= Player.hp then
        -- If this is the last heart and player only has 1 HP, make it blink
        if Player.hp == 1 and i == 1 then
          heart:setAnimation("loop", 4, 1, 2)  -- Blink between dimmed and bright
        else
          heart:setFrame(2)  -- Bright (filled) heart
        end
      else
        heart:setFrame(1)  -- Dimmed (empty) heart
      end
    else
      -- Hide this heart container
      Utils.setLocalY(heart, -999999)  -- Hide
    end
  end
end
