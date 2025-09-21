Barriers = {}

-- Does a lever interaction where the lever causes another entity of
-- a given type to be consumed (so for example an ET_GATE would become
-- consumed and become an ET_GATE_OPEN).
--
-- The lever itself will become ET_LEVER_PULLED and will be consumed too.
function Barriers.doLever(leverEnt, entTypeToConsume)
  -- Consume the lever entity (this will replace it with ET_LEVER_PULLED)
  if leverEnt then Entities.consume(leverEnt) end
  -- Look for the other entity.
  Entities.consumeAllOfType(entTypeToConsume)
end
