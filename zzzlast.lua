Main.init()

function onUpdate()
  Main.update()
end

function onButtonDown(buttonName)
  Menu.onButtonDown(buttonName)
  InventoryUi.onButtonDown(buttonName)
  WorldMap.onButtonDown(buttonName)
end
