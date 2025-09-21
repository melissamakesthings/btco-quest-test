Sfx = {
  SFX = {
    DOOR = "door.wav",
    CLOSE = "close.wav",
    CONFIRM = "confirm.wav",
    DIALOGUE = "dialogue.wav",
    FIRE = "fire.wav",
    GAMEOVER = "gameover.wav",
    HEAL = "heal.wav",
    HIT = "hit.wav",
    HURT = "hurt.wav",
    LIGHTNING = "lightning.wav",
    MISS = "miss.wav",
    OPEN = "open.wav",
    PICKUP = "pickup.wav",
    SELECT = "select.wav",
    SOLVE = "solve.wav",
    TORCH = "torch.wav",
    UPGRADE = "upgrade.wav",
  },
  VOLUME = 0.5,
}

function Sfx.play(sfxId, volumeFactor)
  if not Sfx.SFX[sfxId] then return end
  playSound(Sfx.SFX[sfxId], false, Sfx.VOLUME * (volumeFactor or 1))
end