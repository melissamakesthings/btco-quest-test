Music = {
  -- Default music volume
  DEFAULT_VOLUME = 0.2,
  -- Fade-out duration in seconds.
  FADE_DURATION = 1,

  -- Music tracks
  TRACKS = {
    TITLE = "bgm-title.mp3",
    OVERWORLD = "bgm-overworld.mp3",
    TOWN = "bgm-town.mp3",
    DUNGEON = "bgm-dungeon.mp3",
    DESERT = "bgm-desert.mp3",
    WINTER = "bgm-winter.mp3",
    FINAL = "bgm-final.mp3",
  },

  -- Current state. This can be:
  --   IDLE - not playing anything
  --   PLAYING - playing a track
  --   FADING_OUT - fading out the current track in prep to stop or start a new track
  state = "IDLE",

  -- Currently playing track
  curTrackId = nil,
  -- Current track volume
  curVolume = 0,

  -- If state is FADING_OUT, then this is the time we started fading out.
  fadeStartTime = nil,
  fadeStartVolume = nil,  -- the volume from which the fade started
  -- If not nil, then when we're done fading out we will play this track.
  -- If nil, then we will just stop after fading out.
  trackIdAfterFade = nil,
}

-- Requests that a given track be played, possibly fading out the current
-- track first, if another track is playing.
function Music.requestPlay(trackId)
  -- requestPlay(nil) is the same as requestStop()
  if not trackId then Music.requestStop() return end

  -- If we're already playing this track, do nothing
  if Music.state == "PLAYING" and Music.curTrackId == trackId then
    return
  end
  
  -- If we're currently playing a different track, fade it out first
  if Music.state == "PLAYING" then
    Music.trackIdAfterFade = trackId
    Music.fadeStartTime = unixTime()
    Music.fadeStartVolume = Music.curVolume
    Music.state = "FADING_OUT"
    return
  end
  
  -- If we're already fading out, just update what track to play next
  if Music.state == "FADING_OUT" then
    Music.trackIdAfterFade = trackId
    return
  end
  
  -- If we're idle, start playing immediately
  if Music.state == "IDLE" then
    Music.curTrackId = trackId
    Music.curVolume = Music.DEFAULT_VOLUME
    Music.state = "PLAYING"
    playSound(Music.TRACKS[trackId], true, Music.curVolume)  -- true for looping
  end
end

-- Requests that the current track be stopped (fading it out first).
function Music.requestStop()
  Music.trackIdAfterFade = nil
  -- If we're already fading out, or silent, do nothing.
  if Music.state ~= "PLAYING" then return end
  -- Start fading out the current track.
  Music.fadeStartTime = unixTime()
  Music.fadeStartVolume = Music.curVolume
  Music.state = "FADING_OUT"
end

-- Runs every frame to update the music state.
function Music.update()
  -- Only need to update if doing a fade, otherwise there's nothing to do.
  if Music.state ~= "FADING_OUT" then return end
  local elapsed = unixTime() - Music.fadeStartTime
  local factor = 1 - elapsed / Music.FADE_DURATION
  local desiredVolume = Music.fadeStartVolume * factor
  if desiredVolume <= 0 then
    -- Done fading.
    Music.curVolume = 0
    Music.state = "IDLE"
    stopSound(Music.TRACKS[Music.curTrackId])
    -- Is there another track to play after fading out?
    if Music.trackIdAfterFade then
      local newTrackId = Music.trackIdAfterFade
      Music.trackIdAfterFade = nil  -- Clear it so we don't play it again
      Music.requestPlay(newTrackId)
    end
    return
  end
  -- Update the volume of the currently playing track if it's significantly
  -- different from the desired volume (to avoid unnecessary updates).
  if math.abs(Music.curVolume - desiredVolume) > 0.01 then
    Music.curVolume = desiredVolume
    setSoundVolume(Music.TRACKS[Music.curTrackId], desiredVolume)
  end
end