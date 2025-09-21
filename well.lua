Well = {}

-- Wells allow the player to drink and increase their total health.
-- "Well"-ness. Get it? hehe
-- Each well can only be used once and becomes drained after use.
-- drinkCallback: function that gets called when the player drinks from the well
function Well.interact(ent, drinkCallback)
  Menu.show({
    text = "Drink from the well?",
    options = {"Yes", "No"},
    typewriter = true,
    callback = function(choice)
      Well._callback(choice, ent, drinkCallback)
    end
  })
end

function Well._callback(choice, ent, drinkCallback)
  if choice ~= 1 then return end

  -- Call the specific well's effect callback
  if drinkCallback then
    drinkCallback()
  end
  
  -- Consume the well (this will replace it with ET_WELL_DRAINED)
  Entities.consume(ent)
  
  -- Add particle effect
  ent.thing:particles("puff")
end

-- Health well: increases max HP and heals fully
-- Can be used as a drinkCallback to Well.interact
function Well.doHealthWell()
  Player.hpMax = Player.hpMax + 1
  Player.healFully()
  Sfx.play("SOLVE")
  Menu.showPopup("You feel invigorated! Your maximum health has increased!")
end
