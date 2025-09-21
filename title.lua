-- TITLE SCREEN

Title = {
  OFFSET_Y = 5.5,
}

Title.ORIG_X, Title.ORIG_Y, Title.ORIG_Z = getThing("Title"):getPosition()

function Title.show()
  getThing("Title"):setPosition(Title.ORIG_X, Title.ORIG_Y, Title.ORIG_Z)
  wait(1, function()
    getThing("Title"):startMoveBy(0, Title.OFFSET_Y, 0, 0.5, "parent")
  end)
  wait(2, Title.showMainMenu)
end

function Title.showMainMenu()
  Menu.show({
    text = "",
    options = { 
      "New Game", "Load Game", "About this game" 
    },
    bgImage = "TRANSPARENT",
    offsetY = -Title.OFFSET_Y,
    callback = function(index)
      getThing("Title"):setPosition(0, -999999, 0)
      if index == 1 then
        -- New Game
        FloatingText.show("Starting new game...", "progress")
        wait(1, function() FloatingText.hide() Main.goToState(MS_GAME) end)
      elseif index == 2 then
        -- Load Game
        FloatingText.show("Loading...", "progress")
        Persister.loadGame(function(result)
          Markers.updateForQuestAndArea()
          wait(1, function() Title._onLoadResult(result) end)
        end)
      elseif index == 3 then
        Title.showAbout()
      end
    end
  })
end

function Title.showAbout()
  Menu.show({
    text = "This is an RPG game created by Bruno (btco).\n\nI hope you enjoy!",
    options = { 
      "Open Game Manual", "Back"
    },
    bgImage = "TRANSPARENT",
    offsetY = -Title.OFFSET_Y,
    callback = function(index)
      if index == 1 then
        openUrl("https://docs.google.com/document/d/12scqGDsQGaQuQekdgXN09CoDn1wcmzORZzxbBe4KxJg/edit?tab=t.0")
      end
      Title.show()
    end
  })
end

function Title._onLoadResult(result)
  FloatingText.hide()
  if result == "SUCCESS" then
    Main.goToState(MS_GAME)
  elseif result == "EMPTY" then
    Menu.showPopup("No save data found. Please start a new game.", Title.show)
  elseif result == "BAD_VERSION" then
    Menu.showPopup("Save data is from a different version. Please start a new game.", Title.show)
  else
    Menu.showPopup("** Error! Make sure you're signed in and connected to the internet!", Title.show)
  end
end