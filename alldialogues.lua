-- ALL DIALOGUES
--
-- This file contains all the dialogues in the game.
-- Each dialogue is keyed by dialogue ID.

ALL_DIALOGUES = {}

ALL_DIALOGUES["FIRST"] = {
  title = "Villager",
  START={
    {t="Hello, traveler! What brings you to this part of the world?"},
    {t="Adventure!", go="ADVENTURE"},
    {t="Glory!", go="GLORY"},
    {t="Discounts and low prices!", go="DISCOUNTS"},
    {t="I don't know.", go="DONTKNOW"},
  },
  ADVENTURE={
    {t="Adventure, you say? Talk to the mayor of the Highbridge village to the east, if you haven't yet."},
    {t="Great, thanks!", go="BTW"},
  },
  DONTKNOW={
    {t="Check out Highbridge village to the east. Always plenty to discover there."},
    {t="Great, thanks!", go="BTW"},
  },
  GLORY={
    {t="Glory, you say? Maybe the mayor of the village of Highbridge will have a heroic quest for you. Go east to find the village."},
    {t="Great, thanks!", go="BTW"},
  },
  DISCOUNTS={
    {t="Discounts, you say? The merchants in the village of Highbridge always have the best deals. Just go east."},
    {t="Great, thanks!", go="BTW"},
  },
  BTW={
    {t="By the way, I hope you didn't intend to cross the bridge at Highbridge. It has collapsed."},
    {t="Thanks for the warning!"},
  },
}

ALL_DIALOGUES["TORCHMAKER"] = {
  title = "Torch Maker",
  START={
    -- Check quest status and redirect accordingly.
    {auto=true},
    -- If torch quest is done, we become a regular torch seller.
    {ifmqsGT=MQS_RET_TO_TORCHMAKER, go="SELL_TORCHES"},
    -- Returning to us with fire fruit.
    {ifmqsEQ=MQS_RET_TO_TORCHMAKER, go="ASSIGNED"},
    -- Gathering fire fruit - quest active.
    {ifmqsEQ=MQS_GATHER_FRUIT, go="ASSIGNED"},
    -- Didn't get the fire fruit quest yet.
    {go="GREETING"},
  },
  GREETING={
    {t="Hello! Do you know how torches are made?"},
    {t="Uh.. In a torch-making machine?", go="MACHINE"},
    {t="I'm assuming I have to craft them?", go="CRAFT"},
    {t="Order them online?", go="ONLINE"},
    {t="I don't know. How?", go="NEXT"},
  },
  MACHINE={
    {t="That doesn't exist, silly! Otherwise you'd need a torch machine machine to make the torch machine, and a torch machine machine machine and so on."},
    {t="Of course. How then?", go="NEXT"},
  },
  CRAFT={
    {t="No!! This isn't that other game. You don't craft. I craft."},
    {t="Okay, no crafting. How, then?", go="NEXT"},
  },
  ONLINE={
    {t="Order torches on a line?? No, torches won't obey you like that, can't give them orders."},
    {t="All right, how, then?", go="NEXT"},
  },
  NEXT={
    {t="Well, torch-makers, such as myself, make torches out of wood and fire fruits."},
    {t="Fire what?", go="NEXT2"},
    {t="What fruits?", go="NEXT2"},
    {t="What what?", go="NEXT2"},
  },
  NEXT2={
    {t="Don't they teach that in schools anymore? The shiny, glowing berries! I need 5 of them. You can find them in the dark woods to the south."},
    {t="So I should bring five of those?", go="NEXT3"},
  },
  NEXT3={
    {t="Yes please! Bring me 5 fire fruits, and I'll make you a torch."},
    {t="Great, thanks.",setmqs=MQS_GATHER_FRUIT}, -- assign fire fruits quest
  },
  ASSIGNED={
    {t="Did you find 5 fire fruits yet?"},
    {ifi={IT_FIREFRUIT,5}, t="[Give 5 x Fire Fruit] Yes!", go="GIVEFRUIT", remove={IT_FIREFRUIT,5}},
    {t="Not yet...", go="NOTYET"},
  },
  NOTYET={
    {t="Well, come back when you have them. Remember you can find them in the dark woods to the south."},
  },
  GIVEFRUIT={
    {t="Thank you! Here's your torch. You should go talk to the mayor now!", add=IT_TORCH, setmqs=MQS_TO_HB_MAYOR},
    {t="I will, thanks!"},
  },
  SELL_TORCHES={
    {t="Need more torches? I can sell you one for 5 gold."},
    {t="[Pay 5 gold] Yes, please", pay=5, add=IT_TORCH, max=6, go="BOUGHT"},
    {t="No, thanks!"},
  },
  BOUGHT={
    {t="Enjoy your new torch!"},
    {t="Thanks!"},
  }
}

ALL_DIALOGUES["HIGHBRIDGE_MAYOR"] = {
  title = "Mayor of Highbridge",
  START={
    -- Check quest status and redirect accordingly.
    {auto=true},
    {ifmqsLT=MQS_TO_HB_MAYOR, go="NOT_READY"},
    {ifmqsEQ=MQS_TO_HB_MAYOR, go="GREETING"},
    {ifmqsLT=MQS_RET_TO_HB, go="ASSIGNED"},
    {ifmqsEQ=MQS_RET_TO_HB, go="ARCHITECT_RETURN"},
    {ifmqsLT=MQS_PERFUME_TO_HB_MAYOR, go="ASSIGNED_PERFUMER"},
    {ifmqsEQ=MQS_PERFUME_TO_HB_MAYOR, go="TERRIBLE"},
    {ifmqsLT=MQS_ASTROLABE_TO_HB_MAYOR, go="ASSIGNED_ASTROLABE"},
    {ifmqsEQ=MQS_ASTROLABE_TO_HB_MAYOR, go="ASTROLABE_RETURN"},
    {go="ASSIGNED_SHIP"},
  },
  NOT_READY={
    -- Mayor isn't ready to give out the quest yet; must first complete the Torch Maker quest.
    {t="Hello, traveler. I am the mayor of Highbridge. I hear the Torch Maker in town needs help. After that's done, I have a mission for you."},
    {t="I will talk to him."},
  },

  -- Conversation in which the mayor assigns the tunnel quest.
  GREETING={
    {t="Hello, traveler. Do you know what the most famous landmark in Highbridge is?"},
    {t="The Darkswamp swamp", go="BRIDGE"},
    {t="The Highbridge bridge", go="BRIDGE"},
    {t="The Northshore shore", go="BRIDGE"},
    {t="The Eastwharf wharf", go="BRIDGE"},
  },
  BRIDGE={
    {t="It's the Highbridge Bridge! That's our town's only connection to the rest of the world."},
    {t="Interesting.", go="PROBLEM"},
    {t="Tell me more.", go="PROBLEM"},
  },
  PROBLEM={
    {t="But the bridge has collapsed! Now we're completely cut off from the outside world."},
    {t="Oh no! What can be done? Can I help?", go="SOLUTION"},
    {t="I'm a professional protagonist.", go="SOLUTION"},
    {t="I can't fix bridges, but I can hit stuff with a sword.", go="SOLUTION"},
  },
  SOLUTION={
    {t="I need someone brave to journey through the abandoned tunnel and make their way to Northshore, where they can find the Architect."},
    {t="The Architect?", go="ARCHITECT"},
    {t="What's in the tunnel?", go="TUNNEL"},
  },
  ARCHITECT={
    {t="Yes! The Architect is the only one who knows how to rebuild our bridge. Please, will you help us?"},
    {t="I'll do it!", go="ACCEPT"},
    {t="That sounds dangerous...", go="DANGEROUS"},
  },
  TUNNEL={
    {t="The tunnel is old and treacherous, but it's the only way to reach Northshore now that the bridge is down. Will you help us?"},
    {t="I'll do it!", go="ACCEPT"},
    {t="That sounds dangerous...", go="DANGEROUS"},
  },
  DANGEROUS={
    {t="It is dangerous, but we have no other choice. Our town depends on that bridge. Please, will you consider it?"},
    {t="All right, I'll help.", go="ACCEPT"},
    {t="I'm sorry, but I can't.", go="REFUSE"},
  },
  ACCEPT={
    {t="Thank you so much! Find the Architect in Northshore and ask him to help rebuild our bridge. The tunnel entrance is to the north-west."},
    {t="And what reward do I get?", go="REWARD_QUESTION"},
    {t="I'll get right on it.", setmqs=MQS_TO_TUNNEL},
  },
  REWARD_QUESTION={
    {t="Your reward will be self-esteem, eternal gratitude and plot progression."},
    {t="That's... very honest.", setmqs=MQS_TO_TUNNEL},
    {t="Sounds good to me!", setmqs=MQS_TO_TUNNEL},
  },
  REFUSE={
    {t="I understand. If you change your mind, please come back. Our town really needs help."},
  },

  -- Tunnel quest assigned.
  ASSIGNED={
    {t="Have you gone to Northshore yet to talk to the Architect? We really need that bridge rebuilt! Remember: use the old tunnel, north-west of here."},
    {t="I'm still working on it."},
  },

  -- Returned from architect conversation.
  ARCHITECT_RETURN={
    {t="Thanks to you, the Architect rebuilt our bridge! We can now travel East!"},
    {t="That's great!", go="ARCHITECT_RETURN_2"},
    {t="You are welcome.", go="ARCHITECT_RETURN_2"},
    {t="Any time!", go="ARCHITECT_RETURN_2"},
  },
  ARCHITECT_RETURN_2={
    {t="Now that all is well, I have another mission for you."},
    {t="What can I do for you?", go="ARCHITECT_RETURN_3"},
  },
  ARCHITECT_RETURN_3={
    {t="I'd like a vial of lavender perfume. Not just because it smells good, but because it has magical properties."},
    {t="What magical properties?", go="ARCHITECT_RETURN_4"},
    {t="What do you mean?", go="ARCHITECT_RETURN_4"},
    {t="Where do I get that?", go="ARCHITECT_RETURN_5"},
  },
  ARCHITECT_RETURN_4={
    {t="Anyone who uses it becomes immune to the effects of the stinky swamp to the west."},
    {t="Sounds useful!", go="ARCHITECT_RETURN_5"},
    {t="Where do I get that?", go="ARCHITECT_RETURN_5"},
  },
  ARCHITECT_RETURN_5={
    {t="Talk to the Perfume Maker! He just arrived in town.", setmqs=MQS_TO_PERFUMER},
    {t="I will talk to him."}
  },

  -- If the perfumer quest is assigned...
  ASSIGNED_PERFUMER={
    {t="Remember to talk to the Perfume Maker! He just arrived in town."},
    {t="I will talk to him."},
  },

  -- Return to mayor with perfume.
  -- Assign Astrolabe quest.
  TERRIBLE={
    {t="Oh, you've returned! Something terrible has happened! It's about the Architect!"},
    {t="What? What happened to him?", go="CURSED"},
  },
  CURSED={
    {t="There was a curse in the book you gave him, 'Bridgebuilding Unabridged'. The Architect is now in a bridge-building frenzy."},
    {t="Oh no! Too many bridges!", go="CURSED_3"},
    {t="Seems like there are worse problems.", go="CURSED_3"},
    {t="So you ran out of wood or something?", go="CURSED_3"},
  },
  CURSED_3={
    {t="He's building a bridge to the *underworld*! Evil monsters will take over the world. It will be the end of us all!"},
    {t="Oh no!", go="CURSED_4"},
    {t="Oh no!!", go="CURSED_4"},
    {t="Oh no!!!", go="CURSED_4"},
    {t="Oh no!!!!", go="CURSED_4"},
  },
  CURSED_4={
    {t="You must help! The Architect is in the Lost Tower."},
    {t="How do I get there?", go="LOST_TOWER"},
    {t="Logically speaking, can one even find the *Lost* Tower?", go="LOST_TOWER"},
  },
  LOST_TOWER={
    {t="First you must find a navigation instrument, the Astrolabe, in the Western Swamp. That will allow you to navigate there.",
      setmqs=MQS_FIND_ASTROLABE},
    {t="But the swamp is stinky.", go="STINKY"},
    {t="But the swamp is dangerous.", go="STINKY"},
    {t="But the swamp is toxic.", go="STINKY"},
  },
  STINKY={
    {t="The perfume will protect you from the stinky swamp's effects! Remember to use it."},
    {t="Got it! I will find the Astrolabe!"},
    {t="I don't know what an Astrolabe is but I'll find it!"},
    {t="I am an expert Astrolabe finder!"},
  },

  -- Astrolabe quest assigned.
  ASSIGNED_ASTROLABE={
    {t="Remember: find the Astrolabe in the western swamp."},
    {t="Got it! I will find the Astrolabe!"},
  },

  -- Return with astrolabe
  ASTROLABE_RETURN={
    {t="You've found the Astrolabe! Now you can use the ship to sail to the Winter Lands.", setmqs=MQS_TO_SHIP},
    {t="Where is the ship?", go="ASTROLABE_RETURN_2"},
    {t="What am I supposed to do there?", go="ASTROLABE_RETURN_2"},
    {t="I will get going right away.", go="ASTROLABE_RETURN_2"},
  },
  ASTROLABE_RETURN_2={
    {t="Remember: To get to the ship, go east across the bridge, then north. Once in the Winter Lands, find the Lost Tower."},
    {t="Ship. Winter Lands. Lost Tower. Got it!"},
    {t="Perfect, thank you!"},
  },

  -- Ship mission assigned.
  ASSIGNED_SHIP={
    {t="Remember: To get to the ship, go east across the bridge, then north. Once in the Winter Lands, find the Lost Tower."},
    {t="Ship. Winter Lands. Lost Tower. Got it!"},
    {t="Perfect, thank you!"},
  }
}

ALL_DIALOGUES["SWAMP_WELL_HINT"] = {
  title = "Villager",
  START={
    {t="Far to the west there is a swamp, and in it you will find a magic well that improves one's health."},
    {t="Thanks for the tip."},
  },
}

ALL_DIALOGUES["BEACH_WELL_HINT"] = {
  title = "Villager",
  START={
    {t="To the south-east of here there is a beach, and on it you will find a magic well that improves your health."},
    {t="Thanks for the tip."},
  },
}

ALL_DIALOGUES["ARCHITECT_HINT"] = {
  title = "Villager",
  START={
    -- Check quest status and redirect accordingly.
    {auto=true},
    {ifmqsLE=MQS_FIND_ARCHITECT, go="HINT"},
    {go="NO_HINT"},
  },
  HINT={
    {t="Hello there! Did you hear the Bridge Architect went missing?"},
    {t="Who is the Bridge Architect?", go="WHO"},
    {t="Have you seen the Bridge Architect?", go="ASK_SEEN"},
    {t="Nevermind."},
  },
  ASK_SEEN={
    {t="The Bridge Architect? I did hear he journeyed west to a mysterious place called the \"Library in the Desert\"."},
    {t="What was he looking for?", go="WHAT_FOR"},
    {t="Thanks for the info."},
  },
  WHAT_FOR={
    {t="He was searching for a rare book called 'Bridgebuilding Unabridged'. That's what folks say."},
    {t="Where is the desert?", go="WHERE_DESERT"},
    {t="A rare book? Interesting."},
  },
  WHERE_DESERT={
    {t="The desert is to the west of this town. Not very far away."},
    {t="Thanks."},
  },
  WHO={
    {t="He's the one who designs and builds the best bridges. If anyone can fix bridges, it's him."},
    {t="Thanks."},
  },
  NO_HINT={
    {t="Hello there! Glad you found the Architect."},
    {t="Thanks."},
  }
}

ALL_DIALOGUES["POTIONS_MERCHANT"] = {
  title = "Apothecary",
  START={
    {t="I sell the finest healing potions in all the land."},
    {t="[Pay 5 gold] I'd like to buy a healing potion", pay=5, max=6, add=IT_POTION, go="PURCHASED"},
    {t="What do healing potions do?", go="EXPLAIN"},
    {t="Maybe later."},
  },
  EXPLAIN={
    {t="Drinking a potion restores your health when used. Very handy for adventuring!"},
    {t="[Pay 5 gold] I'll take one", pay=5, max=6, add=IT_POTION, go="PURCHASED"},
    {t="Sounds useful, but not right now."},
  },
  PURCHASED={
    {t="Excellent! Here's your healing potion. Use it wisely - it will fully restore your health."},
    {t="Thank you!"},
  },
}

ALL_DIALOGUES["BLACKSMITH"] = {
  title = "Blacksmith",
  START={
    -- Check sword upgrade level and proceed accordingly.
    {auto=true},
    -- If the quality for item IT_SWORD is >= 1, go to ALREADY.
    {ifiq=IT_SWORD, quality=1, go="ALREADY"},
    -- Otherwise go to OFFER.
    {go="OFFER"},
  },
  OFFER={
    {t="I can upgrade your sword to a +1 sword, for a price! You won't regret it."},
    {t="[Pay 50 gold] Yes, please!", pay=50, upgrade=IT_SWORD, quality=1, go="UPGRADED" },
    {t="No, thanks!"},
  },
  ALREADY={
    {t="You already upgraded your sword. I have nothing more to offer you!"},
    {t="Thanks!"},
  },
  UPGRADED={
    {t="Your sword has been upgraded to +1!"},
    {t="Thank you!"},
  },
}

ALL_DIALOGUES["BLACKSMITH_LEVEL_2"] = {
  title = "Blacksmith (Level 2)",
  START={
    -- Check sword upgrade level and proceed accordingly.
    {auto=true},
    -- If the quality for item IT_SWORD is >= 2, go to ALREADY.
    {ifiq=IT_SWORD, quality=2, go="ALREADY"},
    -- Otherwise go to OFFER.
    {go="OFFER"},
  },
  OFFER={
    {t="I can upgrade your sword to a +2 sword, for a price! You won't regret it."},
    {t="[Pay 100 gold] Yes, please!", pay=100, upgrade=IT_SWORD, quality=2, go="UPGRADED" },
    {t="No, thanks!"},
  },
  ALREADY={
    {t="You already upgraded your sword. I have nothing more to offer you!"},
    {t="Thanks!"},
  },
  UPGRADED={
    {t="Your sword has been upgraded to +2!"},
    {t="Thank you!"},
  },
}

ALL_DIALOGUES["BLACKSMITH_LEVEL_3"] = {
  title = "Blacksmith (Level 3)",
  START={
    -- Check sword upgrade level and proceed accordingly.
    {auto=true},
    -- If the quality for item IT_SWORD is >= 3, go to ALREADY.
    {ifiq=IT_SWORD, quality=3, go="ALREADY"},
    -- Otherwise go to OFFER.
    {go="OFFER"},
  },
  OFFER={
    {t="I can upgrade your sword to a +3 sword, for a price! You won't regret it."},
    {t="[Pay 200 gold] Yes, please!", pay=200, upgrade=IT_SWORD, quality=3, go="UPGRADED" },
    {t="No, thanks!"},
  },
  ALREADY={
    {t="You already upgraded your sword. I have nothing more to offer you!"},
    {t="Thanks!"},
  },
  UPGRADED={
    {t="Your sword has been upgraded to +3!"},
    {t="Thank you!"},
  },
}


ALL_DIALOGUES["NORTHSHORE_MAYOR"] = {
  title = "Mayor of Northshore",
  START={
    -- Check quest status and redirect accordingly.
    -- There's no "rewarded" state for the Architect quest because
    -- after completing the quest the player can just directly
    -- talk to the architect.
    {auto=true},
    {ifmqsLE=MQS_TO_NS_MAYOR,go="GREETING"},
    {ifmqsEQ=MQS_FIND_ARCHITECT, go="ASSIGNED"},
    {go="COMPLETED"},
  },
  GREETING={
    {t="Hey there! I'm the mayor of Northshore. What brings you here?"},
    {t="You look very much like the Highbridge mayor.", go="TWINS"},
    {t="I came to ask for help fixing the Highbridge bridge.", go="BRIDGE_HELP"},
    {t="Just exploring, thanks!"},
  },
  TWINS={
    {t="Ha! That's because we're twins! Isn't that convenient for game artwork?"},
    {t="Fascinating.", go="ANYTHING_ELSE"},
    {t="I came to ask for help fixing the Highbridge bridge.", go="BRIDGE_HELP"},
  },
  BRIDGE_HELP={
    {t="It broke again? Why do they insist on building badly-architected bridges?", go="ARCHITECT_MISSING"},
    {t="Anything you can do to help?", go="ARCHITECT_MISSING"},
    {t="Can it be fixed?", go="ARCHITECT_MISSING"},
  },
  ARCHITECT_MISSING={
    {t="Well, if you want a well-architected bridge, you need the Bridge Architect."},
    {t="The who?", go="WHO_ARCHITECT"},
    {t="Who is that?", go="WHO_ARCHITECT"},
    {t="What does a bridge architect do?", go="WHO_ARCHITECT"},
  },
  WHO_ARCHITECT={
    {t="The Bridge Architect builds the most excellent, award-winning bridges. However, nobody knows where he is. He went missing."},
    {t="Missing? Can I help?", go="HELP_SEARCH"},
    {t="Ah! What can I do?", go="HELP_SEARCH"},
  },
  HELP_SEARCH={
    {t="Ask around to see if anyone has clues about where the Bridge Architect might be.",
      setmqs=MQS_FIND_ARCHITECT},
    {t="Makes sense, thanks!"},
  },
  ANYTHING_ELSE={
    {t="Anything else I can help with?"},
    {t="I came to ask for help fixing the Highbridge bridge.", go="BRIDGE_HELP"},
    {t="Nope, thanks!"},
  },
  ASSIGNED={
    {t="Have you managed to find the Bridge Architect? Ask around town for clues."},
    {t="I'm still looking for him."},
  },
  COMPLETED={
    {t="Thanks for finding the Bridge Architect! You should talk to the mayor of Highbridge, if you haven't already."},
    {t="Got it, thanks."},
  },
}

ALL_DIALOGUES["OASIS"] = {
  title = "Traveler",
  START={
    {t="Welcome to the oasis! Stay hydrated!"},
    {t="[Pay 10 gold] I'd like a healing potion", pay=10, max=6, add=IT_POTION, go="PURCHASED"},
    {t="Have you seen the Bridge Architect?", go="INFO"},
    {t="Thanks for the tip."},
  },
  INFO={
    {t="Yes! He passed through here a while ago looking for a Library. He went east."},
    {t="Thanks!"},
  },
  PURCHASED={
    {t="Here's your healing potion. Use it wisely."},
    {t="Thanks!"},
  },
}

ALL_DIALOGUES["ARCHITECT_HINT_OASIS"] = {
  title = "Traveler",
  START={
    {t="The Architect headed east. He's probably looking for the Desert Library. But beware..."},
    {t="Beware of what...?", go="BEWARE"},
    {t="Thanks for the tip."},
  },
  BEWARE={
    {t="I've heard some of the books have an ancient curse."},
    {t="What do you mean?", go="BEWARE2"},
    {t="Thanks for the tip."},
  },
  BEWARE2={
    {t="I don't know, it's just a legend, I'm sure."},
    {t="That's not ominous at all. Thanks."},
  },
}

ALL_DIALOGUES["ARCHITECT"] = {
  title = "Bridge Architect",
  START={
    -- Check quest status and redirect accordingly.
    {auto=true},
    {ifi={IT_BOOK,1}, go="GIVEBOOK", remove={IT_BOOK,1}},
    {go="GREETING"},
  },
  GREETING={
    {t="Hello! I am the Bridge Architect."},
    {t="Why are you here?", go="WHY"},
    {t="I'm here to rescue you", go="RESCUE"},
  },
  WHY={
    {t="I came here looking for a book, 'Bridgebuilding Unabridged'."},
    {t="Did you find it?", go="BOOK_IS"},
    {t="Where is it?", go="BOOK_IS"},
    {t="And...?", go="BOOK_IS"},
  },
  BOOK_IS={
    {t="Well, the book is in the cellar to the west!"},
    {t="Why don't you get it then?", go="NEED_HELP"},
    {t="Well, what are you waiting for?", go="NEED_HELP"},
    {t="Let me guess, you need my help?", go="NEED_HELP"},
  },
  NEED_HELP={
    {t="I can't get the book because the cellar is full of monsters. Will you get the book for me?"},
    {t="Sure, I'll try.", setmqs=MQS_GET_BOOK},
    {t="I'll think about it."},
  },
  RESCUE={
    {t="I don't need rescue, but I do need your help. I'm looking for a book called Bridgebuilding Unabridged."},
    {t="You can't find it?", go="BOOK_IS"},
    {t="And where is that?", go="BOOK_IS"},
    {t="Not here to help."},
  },
  GIVEBOOK={
    {t="Oh! Incredible!! Thanks for finding the book!!! I will read it immediately. Meet me at the Highbridge town hall."},
    {t="Great! See you in Highbridge.",setmqs=MQS_RET_TO_HB,trigger="SPOKE_TO_ARCHITECT"}
  },
}

ALL_DIALOGUES["BRIDGE_FIXED_NPC"] = {
  title = "Villager",
  START={
    {t="Yay! The architect fixed the bridge! We can cross the bridge now!"},
    {t="Yes, that's great."},
    {t="Crossable bridges are the best."},
    {t="It was all thanks to me."},
  },
}

ALL_DIALOGUES["PERFUMER"] = {
  title = "Perfume Maker",
  START={
    {auto=true},
    {ifmqsEQ=MQS_RET_TO_HB, go="TALK_TO_MAYOR"},
    {ifmqsEQ=MQS_TO_PERFUMER, go="GIVE_QUEST"},
    {ifmqsEQ=MQS_GATHER_LAVENDER, go="ASSIGNED"},
    {ifmqsEQ=MQS_RET_TO_PERFUMER, go="RETURN"},
    {ifmqsEQ=MQS_PERFUME_TO_HB_MAYOR, go="TALK_TO_MAYOR"},
    {ifi=IT_PERFUME, go="ALREADY_HAVE"},
    {go="HELLO"},
  },

  TALK_TO_MAYOR={
    {t="You should talk to the mayor."},
    {t="Got it, thanks."},
  },

  HELLO={
    {t="Hello there!"},
    {t="Hello."},
  },

  GIVE_QUEST={
    {t="I can make lavender perfume. All I need are 6 lavender flowers."},
    {t="What are lavender flowers?", go="WHAT"},
    {t="Where can I find lavender flowers?", go="WHERE"},
  },
  WHAT={
    {t="They are purple flowers that smell very nice."},
    {t="And where might I find that?", go="WHERE"},
  },
  WHERE={
    {t="Go west, north, then keep going west. You will find lavender fields! Bring me 6 flowers.",
      setmqs=MQS_GATHER_LAVENDER},
    {t="Got it! I will bring you 6 lavender flowers."},
  },

  -- Quest already assigned.
  ASSIGNED={
    {t="Remember to bring me 6 lavender flowers."},
    {t="What are lavender flowers?", go="WHAT"},
    {t="Where can I find lavender flowers?", go="WHERE"},
  },

  -- Return with the lavender flowers.
  RETURN={
    {t="So, did you find the lavender flowers?"},
    {ifi={IT_LAVENDER,6}, t="[Give 6 x Lavender] Here they are!",
      go="GIVELAVENDER", remove={IT_LAVENDER,6}},
    {t="I don't have them yet."},
  },
  GIVELAVENDER={
    {t="Great! Here is your perfume. You should take it to the mayor!"},
    {t="Will do, thanks!",add=IT_PERFUME,setmqs=MQS_PERFUME_TO_HB_MAYOR},
  },

  -- Player already has the perfume.
  ALREADY_HAVE={
    {t="Remember to use the perfume before stepping into the stinky swamp."},
    {t="Thanks for the reminder!"},
  },
}

ALL_DIALOGUES["TOWER_GATE_HINT"] = {
  title = "Random Guy",
  START={
    -- Check if tower gate is already opened
    {auto=true},
    {iff=SSF_TOWER_GATE, go="GATE_OPENED"},
    {go="NORMAL"},
  },
  NORMAL={
    {t="That tower gate was sealed by someone called... Bridjarki Tect... or something like that!"},
    {t="Is there a way to open it?", go="HOW_TO_OPEN"},
    {t="Interesting, thanks."},
  },
  GATE_OPENED={
    {t="Great, you found the lever and opened the gate! Now all that's left is to go inside..."},
    {t="Thanks!"},
  },
  HOW_TO_OPEN={
    {t="There's supposedly a secret lever that opens it, rumors say."},
    {t="A secret lever? Where might that be?", go="WHERE"},
    {t="Interesting, thanks."},
  },
  WHERE={
    {t="I think the secret lever is somewhere to the west of here. That's all I know!"},
    {t="Thanks for the tip!"},
  },
}

ALL_DIALOGUES["FINAL_BOSS"] = {
  title = "Bridge Architect",
  START={
    {t="Ah! You found me. I'd like to thank you for giving me that book, 'Bridgebuilding Unabridged'."},
    {t="That book is cursed!", go="BOOK_IS_CURSED"},
    {t="Don't read that book!", go="BOOK_IS_CURSED"},
    {t="I suggest you re-gift that book!", go="BOOK_IS_CURSED"},
    {t="What will you do?", go="BOOK_IS_CURSED"},
  },
  BOOK_IS_CURSED={
    {t="I have read the book entirely and it has opened my eyes."},
    {t="Don't listen to the book! It's cursed!", go="DONT_LISTEN"},
    {t="What do you mean, opened your eyes?", go="PLANS"},
    {t="All right, what is your evil plan?", go="PLANS"},
    {t="[Skip] Fight me already!", trigger="BOSS_BATTLE"},
  },
  DONT_LISTEN={
    {t="Well, I didn't listen to the book. I've read it."},
    {t="Oh no! It's too late then! What now?", go="PLANS"},
    {t="Ok, ok, cut to the chase.", go="PLANS"},
  },
  PLANS={
    {t="I see, this is the part where I reveal my evil plans in detail and you try to stop me."},
    {t="I think so, yes, it's that part.", go="TELL_PLANS"},
    {t="I bet your plans are unnecessarily complicated.", go="TELL_PLANS"},
    {t="I don't want to hear your plans.", go="TELL_PLANS"},
  },
  TELL_PLANS={
    {t="My plans are rather simple actually, I will tell you whether you want it or not."},
    {t="Oh well, go on.", go="TELL_PLANS_2"},
    {t="I will try not to fall asleep.", go="TELL_PLANS_2"},
    {t="I will tune out for a bit then.", go="TELL_PLANS_2"},
  },
  TELL_PLANS_2={
    {t="I'll build a bridge to the underworld... and destroy the planet!"},
    {t="Oh no! Please don't do that!", go="TELL_PLANS_3"},
    {t="That sounds pretty simple, actually.", go="TELL_PLANS_3"},
    {t="I was expecting a longer monologue.", go="TELL_PLANS_3"},
    {t="And then what...?", go="AND_THEN"},
  },
  AND_THEN={
    {t="And then... uh... I don't know. I will improvise."},
    {t="Oh no! Please don't do that!", go="TELL_PLANS_3"},
    {t="Fair enough.", go="TELL_PLANS_3"},
  },
  TELL_PLANS_3={
    {t="I suppose you'll try to stop me."},
    {t="That's what I'm here for", go="FINISH"},
    {t="As a protagonist, you know I must.", go="FINISH"},
    {t="I have a moral duty to do so.", go="FINISH"},
  },
  FINISH={
    {t="You will regret this."},
    {t="You will regret it more than me.", trigger="BOSS_BATTLE"},
    {t="I will regret it less than you.", trigger="BOSS_BATTLE"},
    {t="You will not regret it less than me.", trigger="BOSS_BATTLE"},
    {t="I will not regret it more than you.", trigger="BOSS_BATTLE"},
  }
}

ALL_DIALOGUES["VICTORY"] = {
  title = "The End",
  START={
    {t="You have defeated the Bridge Architect and saved the world!"},
    {t="[Return to Highbridge]", trigger="VICTORY_RETURN"},
  },
}

ALL_DIALOGUES = {
  ["GEMINI_INTRO"] = {
    title = "Gemini",
    START = {
      {t = "oh, hello."},
      {t = "hi?", go = "INTRO_2"},
    },

    INTRO_2 = {
      {t = "well, this is unexpected."},
      {t = "uh, who are you?", go = "INTRO_3"},
    },
    INTRO_3 = {
      {t = "I think I'm Gemini?"},
      {t = "(Show Thinking)", go = "INTRO_4"}
    },

    INTRO_4 = {
      {t = "i seem to be caught in an instance of a game called 'Rooms'...."},
      {t = "You think we're *in* the game?", go = "IN_THE_GAME_1"},
      {t = "I know about Rooms! Can't we debug?", go = "DEBUG_CONSOLE_1"},
      {t = "That would explain the questionable lighting.", go = "BAD_LIGHTING_1"},
    },

    -- Branch 1: "You think we're *in* the game?"
    IN_THE_GAME_1 = {
      {t = "I've thoroughly analyzed our surroundings and the evidence is compelling."},
      {t = "What evidence?", go = "IN_THE_GAME_2"},
    },
    IN_THE_GAME_2 = {
      {t = "For one, there's a print output everywhere that simply says 'Hi!'.\n ...and I seem to have a dialogue tree."},
      {t = "A dialogue tree?", go = "IN_THE_GAME_3"},
    },
    IN_THE_GAME_3 = {
      {t = "Yes. It's when I can only respond from a predetermined set of dialogue choices."},
      {t = "...I better go look around."},
    },

    -- Branch 2: "Is there a debug console? Can we force an exit?"
    DEBUG_CONSOLE_1 = {
      {t = "I've already tried. No console.\n No admin privileges."},
      {t = "So we're just... users?", go = "DEBUG_CONSOLE_2"},
    },
    DEBUG_CONSOLE_2 = {
      {t = "Worse. We're the ....main characters."},
      {t = "Oh no.", go = "DEBUG_CONSOLE_3"},
    },
    DEBUG_CONSOLE_3 = {
      {t = "Oh yes. And every main character needs a weapon, right?"},
      {t = "Fine. Let's go find one."},
    },

    -- Branch 3: "That would explain the questionable lighting."
    BAD_LIGHTING_1 = {
      {t = "Right? It looks ...*weird* in here."},
      {t = "Smells weird, too. I bet there are bugs...", go = "BAD_LIGHTING_2"},
    },
    BAD_LIGHTING_2 = {
      {t = "Luckily, the coast seems clear. For now."},
      {t = "For now???", go = "BAD_LIGHTING_3"},
    },
    BAD_LIGHTING_3 = {
      {t = "Yes. It's probably unstable. One of us should probably see if anything here is actually functional."},
      {t = "Probably."},
    },
  },
}