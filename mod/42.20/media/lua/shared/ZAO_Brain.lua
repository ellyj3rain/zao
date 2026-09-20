-- ZAO_Brain - durable brain-health history for people whose pathogen state
-- belongs to Zombie Awareness.
--
-- SAO owns the body observations and the effects those observations have on
-- survivor behaviour.  ZAO owns this record when it is installed because
-- terminal pathogen state is one of the causes recorded in the history.  The
-- table is deliberately separate from StateStore.people: an uninfected person
-- can have a toxic or septic brain-health history without acquiring a fake
-- pathogen record.

ZAO = ZAO or {}
ZAO.Brain = ZAO.Brain or {}
local Brain = ZAO.Brain

function Brain.stateFor(personId, create)
    if personId == nil or not ZAO.StateStore then return nil end
    local store = ZAO.StateStore.store()
    if not store then return nil end
    store.brain = store.brain or {}
    local key = tostring(personId)
    local state = store.brain[key]
    if not state and create then
        state = { version = 2, history = {} }
        store.brain[key] = state
    end
    return state
end

function Brain.historyOf(personId)
    local state = Brain.stateFor(personId, false)
    return state and state.history or nil
end

return Brain
