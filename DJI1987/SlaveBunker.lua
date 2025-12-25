-- ===== Bunker Production Force =====
-- Fast production only - let game system handle stock production naturally
    
-- Production time
local PRODUCTION_TIME_STORAGE = 2708309
local BUNKER_INDEX = 5
local FAST_PRODUCTION_TIME_MS = 1000
    
-- Bunker tunables
local BUNKER_PRODUCTION_TUNABLES = {215868155, 631477612, 818645907}
local BUNKER_COST_TUNABLES = {-1652502760, 1647327744}
    
script.run_in_callback(function()
    local production_time_g = ScriptGlobal.new(PRODUCTION_TIME_STORAGE + BUNKER_INDEX)
    
    -- Apply tunables once
    for _, tunable_id in ipairs(BUNKER_PRODUCTION_TUNABLES) do
        tunables.set_int(tunable_id, 1)
    end
    for _, tunable_id in ipairs(BUNKER_COST_TUNABLES) do
        tunables.set_int(tunable_id, 1)
    end
    
    while true do
        script.yield(100)
        
        -- Continuously force fast production time
        -- This lets the game's production system run naturally, consuming supplies and producing stock
        if production_time_g:can_access() then
            production_time_g:set_int(FAST_PRODUCTION_TIME_MS)
        end
    end
end)