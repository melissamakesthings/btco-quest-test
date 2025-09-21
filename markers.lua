-- MARKERS
-- Markers are the little triangles that indicate what entity or entities the
-- user is supposed to interact with at this point in the quest.

Markers={
  DEFAULT_MARKER_HEIGHT = 25,

  -- We use an extra field "attachedToEid" to record which entity ID this
  -- marker currently tracks.
  things={
    getThing("Marker 1"), getThing("Marker 2"), getThing("Marker 3"),
    getThing("Marker 4"), getThing("Marker 5"), getThing("Marker 6"),
  },

  -- Area for which we have set up the markers, nil if never set.
  areaX = nil, areaY = nil,
  -- Quest state for which we have set up the markers, nil if never set.
  questState = nil
}

function Markers.reset()
  for i, marker in ipairs(Markers.things) do
    marker:setPosition(999999, 0, 0) -- hide it
    marker.attachedToEid = nil
  end
end

-- Updates the markers to match the quest and the area.
-- This must be called when either the main quest state is changed, or
-- when the area changes.
function Markers.updateForQuestAndArea()
  local qs = Persister.getMainQuestState()
  -- For performance: if there is no change in the quest state or area, don't
  -- do anything (protection against this being called repeatedly).
  if qs == Markers.questState and Markers.areaX == Area.areaX and Markers.areaY == Area.areaY then
    return
  end
  Markers.questState = qs
  Markers.areaX, Markers.areaY = Area.areaX, Area.areaY
  Markers.reset()
  local qsInfo = QuestDesc.MQS_INFO[qs]
  if not qsInfo or not Markers.areaX or not Markers.areaY then return end
  if qsInfo.targetArea ~= Area.areaX .. " " .. Area.areaY then
    -- No quest markers for this area.
    return
  end
  if not qsInfo.targetEntType then
    -- No entities to mark.
    return
  end
  local entsToMark = Entities.getEntsByType(qsInfo.targetEntType)
  local nextMarkIndex = 1
  for _, ent in ipairs(entsToMark) do
    local marker = Markers.things[nextMarkIndex]
    nextMarkIndex = nextMarkIndex + 1
    if marker then
      marker:setPosition(ent.x, ent.recipe.markerY or Markers.DEFAULT_MARKER_HEIGHT, ent.z)
      marker.attachedToEid = ent.eid
    end
  end
end

function Markers.checkDeletedEnts()
  for i, marker in ipairs(Markers.things) do
    if marker.attachedToEid and not Entities.exists(marker.attachedToEid) then
      -- The entity this marker was attached to no longer exists.
      marker:setPosition(999999, 0, 0) -- hide it
      marker.attachedToEid = nil
    end
  end
end
