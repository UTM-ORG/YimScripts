local set_stat = stats.set_int -- DJ1987
local get_stat = stats.get_int
    
-- Configuration
local RELOAD_INTERVAL_MS = 300000  -- 5 minutes in milliseconds
    
-- Max values for each stat
local MAX_VALUES = {
    ["MPX_NO_BOUGHT_YUM_SNACKS"] = 30,          -- P's & Q's
    ["MPX_NO_BOUGHT_HEALTH_SNACKS"] = 15,        -- EgoChaser
    ["MPX_NO_BOUGHT_EPIC_SNACKS"] = 5,           -- Meteorite
    ["MPX_NUMBER_OF_ORANGE_BOUGHT"] = 10,        -- eCoLa
    ["MPX_NUMBER_OF_BOURGE_BOUGHT"] = 10,        -- Pisswasser
    ["MPX_NUMBER_OF_CHAMP_BOUGHT"] = 5,          -- Blêuter'd Champagne
    ["MPX_CIGARETTES_BOUGHT"] = 20,              -- Smokes
    ["MPX_NUMBER_OF_SPRUNK_BOUGHT"] = 10,        -- Sprunk
    ["MPX_MP_CHAR_ARMOUR_1_COUNT"] = 10,         -- Super Light Armor
    ["MPX_MP_CHAR_ARMOUR_2_COUNT"] = 10,         -- Light Armor
    ["MPX_MP_CHAR_ARMOUR_3_COUNT"] = 10,         -- Standard Armor
    ["MPX_MP_CHAR_ARMOUR_4_COUNT"] = 10,         -- Heavy Armor
    ["MPX_MP_CHAR_ARMOUR_5_COUNT"] = 10,         -- Super Heavy Armor
    ["MPX_BREATHING_APPAR_BOUGHT"] = 20,         -- Rebreather
}
    
-- Helper function to get current game time in milliseconds
local function get_game_timer_ms()
    local ok, timer = pcall(function()
        if type(MISC) == "table" and MISC.GET_GAME_TIMER then
            return MISC.GET_GAME_TIMER()
        end
        return nil
    end)
    if ok and timer then
        return timer
    end
    return nil
end
    
-- Function to check if any stats are below max and reload if needed
-- Returns true if reload was performed, false otherwise
local function check_and_reload_snacks_and_armor()
    local needs_reload = false
    
    -- Check each stat to see if it's below max
    for stat_name, max_value in pairs(MAX_VALUES) do
        local ok, current_value = pcall(function()
            if stats and stats.get_int then
                return get_stat(stat_name)
            end
            return nil
        end)
        
        if ok and current_value ~= nil then
            if current_value < max_value then
                needs_reload = true
                break  -- Found at least one below max, no need to check others
            end
        else
            -- If we can't read the stat, assume it needs reload (safer)
            needs_reload = true
            break
        end
    end
    
    -- Only reload if needed
    if needs_reload then
        for stat_name, max_value in pairs(MAX_VALUES) do
            set_stat(stat_name, max_value)
        end
        return true
    end
    
    return false
end
    
-- Function to check if freemode script is running
local function check_freemode_running()
    local ok, result = pcall(function()
        if type(SCRIPT) == "table" then
            local func = SCRIPT["GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH"]
            if type(func) == "function" then
                local freemode_hash = util.joaat("freemode")
                local count = func(freemode_hash)
                return count > 0
            end
        end
        return nil
    end)
    
    if ok and result ~= nil then
        return result
    end
    
    -- If check failed, return nil (unknown state)
    return nil
end
    
-- Function to check if player is online using network natives (fallback)
local function check_network_online()
    local ok, result = pcall(function()
        -- Load natives if needed
        if natives and natives.load_natives then
            natives.load_natives()
        end
        
        if type(NETWORK) == "table" and NETWORK.NETWORK_IS_SESSION_STARTED then
            return NETWORK.NETWORK_IS_SESSION_STARTED()
        end
        
        return nil
    end)
    
    if ok and result ~= nil then
        return result
    end
    
    return nil
end
    
script.run_in_callback(function()
    log.info("==========================================================")
    log.info("================ SnackArmor Script Loaded ================")
    log.info("==========================================================")
    
    -- Wait a bit for game to initialize before checking
    script.yield(2000)
    
    -- Check if freemode script is running (single player detection)
    local freemode_running = check_freemode_running()
    local singleplayer_warned = false
    
    -- If freemode check is unknown, try network check as fallback first (silently)
    if freemode_running == nil then
        local network_online = check_network_online()
        if network_online == true then
            freemode_running = true
        elseif network_online == false then
            freemode_running = false
        end
    end
    
    -- If not confirmed online, wait and keep checking
    if freemode_running ~= true then
        -- Only show singleplayer warning if we're confirmed offline (not unknown)
        if freemode_running == false then
            log.warn("====== DETECTED: Singleplayer - Waiting for Online =======")
            singleplayer_warned = true
        end
        
        while freemode_running ~= true do
            script.yield(1000)  -- Wait 1 second between checks
            
            freemode_running = check_freemode_running()
            
            -- If freemode check is still unknown, try network check as fallback (silently)
            if freemode_running == nil then
                local network_online = check_network_online()
                if network_online == true then
                    freemode_running = true
                    break
                elseif network_online == false then
                    -- Network check confirms offline
                    freemode_running = false
                    -- Show warning if we haven't already
                    if not singleplayer_warned then
                        log.warn("====== DETECTED: Singleplayer - Waiting for Online =======")
                        singleplayer_warned = true
                    end
                end
                -- If network check also returns nil, keep waiting silently
            end
        end
    end
    
    -- Show final online detection message
    log.info("===== DETECTED: Online - Starting SnackArmor Script ======")
    
    -- Wait 4 seconds after online detection to allow session to fully load
    script.yield(4000)
    
    -- Initialize timer tracking
    local script_start_time = get_game_timer_ms()
    local last_reload_time = script_start_time
    
    -- Initial check and reload on script start
    local reloaded = check_and_reload_snacks_and_armor()
    if reloaded then
        notify.info("SnackArmor", "Snacks and Armor Reloaded")
        log.info("================= Initial Reload Complete ================")
    else
        log.info("=========== All Items Maxed - Skipping Reload ============")
    end
    
    -- Main loop - check and reload every 5 minutes if needed
    while true do
        local current_time = get_game_timer_ms()
        
        if current_time and last_reload_time and current_time > last_reload_time then
            local elapsed_ms = current_time - last_reload_time
            
            if elapsed_ms >= RELOAD_INTERVAL_MS then
                -- Check and reload snacks and armor only if needed
                local reloaded = check_and_reload_snacks_and_armor()
                if reloaded then
                    notify.info("SnackArmor", "Snacks and Armor Reloaded")
                    log.info("=============== Snacks and Armor Reloaded ===============")
                else
                    log.info("=========== All Items Maxed - Skipping Reload ============")
                end
                
                -- Update last reload time
                last_reload_time = current_time
            end
        end
        
        -- Yield to prevent excessive CPU usage
        script.yield(1000)  -- Check every second
    end
end)