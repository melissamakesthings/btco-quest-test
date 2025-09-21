# rooms-btco-quest

This is an RPG game for Rooms developed by [Bruno Oliveira "btco"](https://twitter.com/btco_code).
You can play it [here](https://rooms.xyz/btco/quest).

## Build Requirements

The build script was only tested on MacOS, but it might work
on other operating systems too with minimal modifications.

You must install:

  * Node (for running the JS build scripts)
  * Tiled (for editing maps)

## Build Instructions

First, in Rooms, open https://rooms.xyz/btco/quest and save it as your
own game.

Run `build.sh` to build. This will process the map (world.tmx)
and all the Lua files to create an output text file in `/tmp/out.txt`,
which will then be opened in your default text editor.

Take the contents of this file and paste it as the code
for the **Game** object.

The game should now run successfully.

Feel free to create your own game based on this engine!
Modify the dialogues, map, items, anything you want.

nb: This is my personal fork for learning and experimentation.

