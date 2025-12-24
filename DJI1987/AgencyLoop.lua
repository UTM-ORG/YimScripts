local ncs = stats.set_int -- Creds to ImagineNothing, Author DJ1987
 
-- ===== Agency Safe Configuration =====
-- Agency safe collection flag global (from ClaimSafeEarnings.cpp: 2708850)
local GLOBAL_AGENCY_SAFE_COLLECT = 2708850
-- Agency safe cash value global (discovered via diagnostic: Global_1845274[player_id * 877 + 807])
local BASE_GLOBAL_SAFE = 1845274
local ENTRY_SIZE_SAFE = 877
local SAFE_OFFSET = 807
local SAFE_CAPACITY = 250000  -- Maximum safe capacity
local LOG_PREFIX = "=============== "
local STATS_INTERVAL_MS = 300000  -- 5 minutes in milliseconds
 
-- Initialize safe collection flag global
local g_safe_collect = ScriptGlobal.new(GLOBAL_AGENCY_SAFE_COLLECT)
 
-- Check if passive payout is supported (not in activity session)
-- Cache the result to avoid repeated native calls
local passive_payout_supported_cache = nil
local passive_payout_check_count = 0
local unsupported_session_warned = false
-- Heuristic tracking: Monitor if safe value increases after forcing payouts
local payout_attempts_without_increase = 0
local last_safe_value_before_payout = nil
local MAX_PAYOUT_ATTEMPTS_WITHOUT_INCREASE = 6  -- If safe doesn't increase after 6 payout attempts, likely unsupported
 
-- Cache native function references at startup (after natives.load_natives())
local network_is_activity_session = nil
local netshopping_is_session_refresh_pending = nil
 
-- Use YimMenu's built-in joaat function from util table
-- No need to implement manually - util.joaat() is available
 
local function is_passive_payout_supported()
    -- Re-check every 5 calls to handle session changes more responsively
    passive_payout_check_count = passive_payout_check_count + 1
    local was_supported = passive_payout_supported_cache
    if passive_payout_supported_cache ~= nil and passive_payout_check_count < 5 then
        return passive_payout_supported_cache
    end
    
    passive_payout_check_count = 0
    
    -- Method 1: Check if safe value is increasing after payout attempts (heuristic)
    -- This catches sessions where safe is readable but doesn't increment (e.g., freemode activities)
    -- Note: This check is performed in the main loop after payout attempts, not here
    -- The main loop sets passive_payout_supported_cache based on payout effectiveness
    
    -- Method 2: Try NETWORK_IS_ACTIVITY_SESSION native (if available)
    -- This catches mission lobbies and other activity sessions
    local ok, is_activity = pcall(function()
        -- Use cached function reference if available
        if network_is_activity_session and type(network_is_activity_session) == "function" then
            return network_is_activity_session()
        end
        -- Fallback: Check NETWORK table (available after natives.load_natives())
        if type(NETWORK) == "table" then
            local func = NETWORK["NETWORK_IS_ACTIVITY_SESSION"]
            if type(func) == "function" then
                return func()
            end
        end
        return nil
    end)
    
    if ok and is_activity ~= nil then
        local result = not is_activity  -- If is_activity is true, result is false (not supported)
        
        -- Show warning when switching to unsupported session (only once)
        if not result and (was_supported == nil or was_supported == true) and not unsupported_session_warned then
            log.warn("=== DETECTED: UNSUPPORTED SESSION - SWITCH TO FREEMODE ===")
            unsupported_session_warned = true
        elseif result and (was_supported == false) then
            unsupported_session_warned = false
        end
        
        passive_payout_supported_cache = result
        return result
    end
    
    -- Method 3: Fallback - default to SUPPORTED (freemode is default) if we can't check
    local result = true
    if was_supported == false then
        unsupported_session_warned = false
    end
    passive_payout_supported_cache = result
    return result
end
 
-- Wrapper for logging that checks if we should suppress logs
-- Optimized: Use cache directly instead of calling function
local function safe_log_info(message)
    if passive_payout_supported_cache == true then
        log.info(message)
    end
end
 
local function safe_log_warn(message)
    if passive_payout_supported_cache == true then
        log.warn(message)
    end
end
 
local function safe_log_error(message)
    if passive_payout_supported_cache == true then
        log.error(message)
    end
end
 
-- Get current player ID
local function get_player_id()
    local ok, pid = pcall(function()
        if PLAYER and PLAYER.PLAYER_ID then
            return PLAYER.PLAYER_ID()
        end
        return 0
    end)
    if ok and pid ~= nil then
        return pid
    end
    return 0
end
 
-- Check if transaction is pending
-- Native is available in NETSHOPPING table after natives.load_natives()
-- Defined as: NET_GAMESERVER_IS_SESSION_REFRESH_PENDING=function()return _I(2743,'=b')end
local function is_transaction_pending()
    -- Use cached function reference if available
    if netshopping_is_session_refresh_pending and type(netshopping_is_session_refresh_pending) == "function" then
        local ok, pending = pcall(function()
            return netshopping_is_session_refresh_pending()
        end)
        if ok then
            return pending == true
        end
    end
    -- Fallback: Check NETSHOPPING table directly
    local ok, pending = pcall(function()
        if type(NETSHOPPING) == "table" then
            local func = NETSHOPPING["NET_GAMESERVER_IS_SESSION_REFRESH_PENDING"]
            if type(func) == "function" then
                return func()
            end
        end
        return false
    end)
    if not ok then
        return false
    end
    return pending == true
end
 
-- Wait for transaction to complete
local function wait_for_transaction(timeout_ms)
    timeout_ms = timeout_ms or 30000  -- Default 30 second timeout
    local max_iterations = math.floor(timeout_ms / 100)  -- Check every 100ms
    local iterations = 0
    
    while is_transaction_pending() do
        if iterations >= max_iterations then
            safe_log_warn(LOG_PREFIX .. "Transaction wait timeout")
            return false
        end
        iterations = iterations + 1
        script.yield(100)  -- Check every 100ms
    end
    return true
end
 
-- Format number with commas (e.g., 5000000 -> "5,000,000")
local function format_money(amount)
    local formatted = tostring(amount)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then
            break
        end
    end
    return formatted
end
 
-- Read Agency safe cash value
local function read_safe_value()
    local ok, value = pcall(function()
        local player_id = get_player_id()
        local absolute = BASE_GLOBAL_SAFE + (player_id * ENTRY_SIZE_SAFE) + SAFE_OFFSET
        local g_safe = ScriptGlobal.new(absolute)
        
        if g_safe:can_access() then
            return g_safe:get_int()
        else
            return nil
        end
    end)
    
    if ok and value ~= nil then
        return value
    end
    return nil
end
 
-- Collect Agency safe earnings (from Vinewood App source)
-- Setting the collection flag global to 1 (TRUE) triggers the collection
-- This matches the pattern used in ClaimSafeEarnings.cpp and for Hands on Car Wash (2708890)
local function collect_agency_earnings(safe_value)
    -- Wait for any pending transactions before collecting
    if is_transaction_pending() then
        log.info("============ *DETECTED PENDING TRANSACTIONS* =============")
        wait_for_transaction()
    end
    
    local ok, err = pcall(function()
        if g_safe_collect:can_access() then
            g_safe_collect:set_int(1) -- Set to TRUE to trigger collection
        else
            error("Global for Collection Not Accessible")
        end
    end)
 
    if ok then
        safe_log_info("============ Collecting Agency Safe $" .. format_money(safe_value) .. " =============")
        
        -- Wait for transaction to complete after collection
        wait_for_transaction()
        
        return safe_value  -- Return the amount collected
    else
        safe_log_error(LOG_PREFIX .. "Safe Collection Failed - " .. tostring(err))
        return 0
    end
end
 
-- Force passive income payout
local function boost_agency_state()
    ncs("mpx_FIXER_COUNT", 500)                 -- high contract count to unlock payouts
    ncs("mpx_FIXER_PASSIVE_PAY_TIME_LEFT", -1)  -- forces payout timer to instantly end
end
 
-- Helper function to check safe and collect if needed (consolidates duplicate code)
local function check_and_collect_safe(session_supported)
    local safe_value = read_safe_value()
    if safe_value ~= nil then
        -- Only log if session is supported AND safe value is not $0 (avoid spamming $0 in unsupported sessions)
        if session_supported and safe_value > 0 then
            log.info(LOG_PREFIX .. "Agency Safe: $" .. format_money(safe_value))
        end
        
        if safe_value >= SAFE_CAPACITY then
            local collected = collect_agency_earnings(safe_value)
            if collected > 0 then
                return safe_value, collected  -- Return both values for stats tracking
            end
            script.yield(2000) -- Wait for collection to process
        end
    end
    return safe_value, 0
end
 
script.run_in_callback(function()
    -- Load natives if needed
    if natives and natives.load_natives then
        local ok, err = pcall(function()
            natives.load_natives()
        end)
        if not ok then
            log.error("Failed to load natives: " .. tostring(err))
        end
    end
    
    -- Cache native function references after loading natives
    if type(NETWORK) == "table" then
        network_is_activity_session = NETWORK["NETWORK_IS_ACTIVITY_SESSION"]
    end
    if type(NETSHOPPING) == "table" then
        netshopping_is_session_refresh_pending = NETSHOPPING["NET_GAMESERVER_IS_SESSION_REFRESH_PENDING"]
    end
    
    -- Check if freemode script is running (single player check)
    -- In single player, freemode script is not running, so we should wait for multiplayer
    local freemode_running = false
    local ok_freemode, result = pcall(function()
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
    
    if ok_freemode and result ~= nil then
        freemode_running = result
    end
    
    -- Always print startup message to indicate script is loaded
    log.info("==========================================================")
    log.info("=============== Agency Script Loaded [2.0] ===============")
    log.info("==========================================================")
    
    -- Wait for freemode script to start (multiplayer)
    if not freemode_running then
        log.warn("====== DETECTED: Singleplayer - Waiting for Online =======")
        while not freemode_running do
            script.yield(1000)  -- Check every second
            ok_freemode, result = pcall(function()
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
            if ok_freemode and result ~= nil then
                freemode_running = result
            end
        end
        log.info("======= DETECTED: Online - Starting Agency Script ========")
    end
    
    -- Clear cache on script start to force immediate check
    passive_payout_supported_cache = nil
    passive_payout_check_count = 10  -- Force immediate check
    unsupported_session_warned = false
    -- Reset heuristic tracking
    payout_attempts_without_increase = 0
    last_safe_value_before_payout = nil
    
    -- Wait 4 seconds before starting any safe reading or payout cycles
    -- This prevents the unsupported session check from starting during initialization
    script.yield(4000)
    
    -- Check session type on startup (warning will be shown by is_passive_payout_supported if needed)
    is_passive_payout_supported()
    
    -- Stats tracking (cumulative, never reset)
    local total_collected = 0
    local collection_count = 0
    local payout_tick_count = 0  -- Count payout ticks (each ~7.1 seconds)
    local total_payout_ticks = 0  -- Total ticks since script start (for time calculation)
    local STATS_TICK_THRESHOLD = math.floor(STATS_INTERVAL_MS / 7100)  -- ~42 ticks for 5 minutes
    
    while true do
        -- Check session support status first (use cache to avoid spam)
        -- Force a fresh check at the start of each main loop iteration to detect session changes
        local session_supported = passive_payout_supported_cache
        if session_supported == nil then
            -- Cache not set yet, do a check
            session_supported = is_passive_payout_supported()
        end
        
        -- Re-check more frequently if we're in unsupported mode to detect return to supported
        if session_supported == false then
            -- In unsupported mode, check more frequently (every 2 iterations)
            passive_payout_check_count = passive_payout_check_count + 1
            if passive_payout_check_count >= 2 then
                passive_payout_check_count = 0
                -- Force a fresh check
                passive_payout_supported_cache = nil
                session_supported = is_passive_payout_supported()
                
                -- If we're back in a supported session, reset warning flag and update cache
                if session_supported == true then
                    unsupported_session_warned = false
                    payout_attempts_without_increase = 0
                    last_safe_value_before_payout = nil
                    log.info("===== DETECTED: Supported Session - Resuming Script ======")
                    -- Update cache to ensure consistency
                    passive_payout_supported_cache = true
                    -- session_supported is now true, so we'll skip the unsupported block below
                end
            end
        else
            -- In supported mode, check every 5 calls (normal frequency)
            passive_payout_check_count = 5  -- Force re-check
        end
        
        -- Skip all processing if session is unsupported (prevents safe value logging)
        -- Re-check session_supported in case it was updated above
        if session_supported == false then
            -- Still run payout cycle in background for heuristic detection, but suppress all logging
            for i = 1, 13 do
                -- Track safe value before forcing payout (for heuristic detection only)
                local safe_before_payout = read_safe_value()
                if safe_before_payout ~= nil then
                    last_safe_value_before_payout = safe_before_payout
                end
                
                -- force passive income to be ready (for heuristic detection)
                boost_agency_state()
                script.yield(7100)
                
                -- Check safe value after payout (for heuristic only, no logging)
                local current_safe = read_safe_value()
                if current_safe ~= nil and last_safe_value_before_payout ~= nil then
                    -- Heuristic: Check if safe value increased meaningfully (at least 10,000)
                    -- Also require that we're not starting from $0 (to avoid false positives after collection)
                    if current_safe > last_safe_value_before_payout and last_safe_value_before_payout > 0 then
                        local increase_amount = current_safe - last_safe_value_before_payout
                        if increase_amount >= 10000 then
                            -- Meaningful increase detected - mark as supported
                            payout_attempts_without_increase = 0
                            if passive_payout_supported_cache == false then
                                passive_payout_supported_cache = true
                                passive_payout_check_count = 5
                                unsupported_session_warned = false
                                log.info("===== DETECTED: Supported Session - Resuming Script ======")
                                -- Break out of payout cycle to restart main loop with supported session
                                break
                            end
                        else
                            -- Small increase (likely noise) - don't mark as supported, continue counting
                            if current_safe < SAFE_CAPACITY then
                                payout_attempts_without_increase = payout_attempts_without_increase + 1
                            end
                        end
                    elseif current_safe <= last_safe_value_before_payout or last_safe_value_before_payout == 0 then
                        -- Safe didn't increase, decreased, or we're starting from $0 - count as failure
                        if current_safe < SAFE_CAPACITY then
                            payout_attempts_without_increase = payout_attempts_without_increase + 1
                        else
                            payout_attempts_without_increase = 0
                        end
                    end
                end
            end
            -- Wait before restarting main loop
            script.yield(2000)
        else
            -- Session is supported - proceed with normal operations
            -- Check if transaction is pending before proceeding
            if is_transaction_pending() then
                log.info("============ *DETECTED PENDING TRANSACTIONS* =============")
                wait_for_transaction()
            end
            
            -- Update session_supported from cache in case it changed
            session_supported = passive_payout_supported_cache == true
            
            -- Check safe value before starting payout cycle
            local safe_value, collected = check_and_collect_safe(session_supported)
            if collected > 0 then
                total_collected = total_collected + collected
                collection_count = collection_count + 1
                -- Reset payout tracking after collection
                payout_attempts_without_increase = 0
                last_safe_value_before_payout = nil
            end
            
            -- Run payout cycle 13 times
            for i = 1, 13 do
                -- Check for pending transactions before proceeding
                if is_transaction_pending() then
                    log.info("============ *DETECTED PENDING TRANSACTIONS* =============")
                    wait_for_transaction()
                    -- Re-check after waiting - if still pending, skip this iteration
                    if is_transaction_pending() then
                        if session_supported then
                            log.info(LOG_PREFIX .. "=========== Transaction Pending: Skipping Cycle ==========")
                        end
                        script.yield(1000)  -- Wait 1 second before next check
                    else
                        -- Transaction cleared, proceed with payout
                        -- Track safe value before forcing payout (for heuristic detection)
                        local safe_before_payout = read_safe_value()
                        if safe_before_payout ~= nil then
                            last_safe_value_before_payout = safe_before_payout
                        end
                        
                        -- force passive income to be ready
                        boost_agency_state()
                        script.yield(7100)
                    end
                else
                    -- Always run payout cycle (even if unsupported) to allow heuristic detection
                    -- Track safe value before forcing payout (for heuristic detection)
                    local safe_before_payout = read_safe_value()
                    if safe_before_payout ~= nil then
                        last_safe_value_before_payout = safe_before_payout
                    end
                    
                    -- force passive income to be ready
                    boost_agency_state()
 
                    -- wait for script to tick and pay out
                    script.yield(7100)
                end
                
                -- Check for pending transactions before checking safe value
                if not is_transaction_pending() then
                    -- Check safe value after each payout tick (always check for heuristic, but only log if supported)
                    local current_safe = read_safe_value()
                    if current_safe ~= nil then
                        -- Heuristic: Check if safe value increased after payout attempt
                        if last_safe_value_before_payout ~= nil then
                            if current_safe <= last_safe_value_before_payout then
                                -- Safe didn't increase (or decreased, possibly due to collection)
                                -- Only count as failure if safe didn't increase AND we didn't just collect
                                if current_safe < SAFE_CAPACITY then
                                    payout_attempts_without_increase = payout_attempts_without_increase + 1
                                    if payout_attempts_without_increase >= MAX_PAYOUT_ATTEMPTS_WITHOUT_INCREASE then
                                        -- Safe hasn't increased after multiple payout attempts - likely unsupported session
                                        if passive_payout_supported_cache ~= false then
                                            passive_payout_supported_cache = false
                                            passive_payout_check_count = 5  -- Force re-check
                                            session_supported = false  -- Update local variable immediately to suppress logging
                                            if not unsupported_session_warned then
                                                log.warn("=== DETECTED: UNSUPPORTED SESSION - SWITCH TO FREEMODE ===")
                                                unsupported_session_warned = true
                                            end
                                        end
                                    end
                                else
                                    -- Safe is at capacity, might have been collected - reset counter
                                    payout_attempts_without_increase = 0
                                end
                            else
                                -- Safe increased - check if increase is meaningful (at least 10,000 to avoid false positives)
                                -- Also require that we're not starting from $0 (to avoid false positives after collection)
                                local increase_amount = current_safe - last_safe_value_before_payout
                                if increase_amount >= 10000 and last_safe_value_before_payout > 0 then
                                    -- Meaningful increase detected - reset counter and mark as supported
                                    payout_attempts_without_increase = 0
                                    if passive_payout_supported_cache == false then
                                        passive_payout_supported_cache = true
                                        passive_payout_check_count = 5  -- Force re-check
                                        unsupported_session_warned = false  -- Reset warning flag when switching back to supported
                                        log.info("===== DETECTED: Supported Session - Resuming Script ======")
                                    end
                                else
                                    -- Small increase, or starting from $0 - don't mark as supported yet
                                    -- Continue counting attempts without meaningful increase
                                    if current_safe < SAFE_CAPACITY then
                                        payout_attempts_without_increase = payout_attempts_without_increase + 1
                                    end
                                end
                            end
                        end
                        
                        -- Update session_supported from cache in case it changed during this iteration
                        session_supported = passive_payout_supported_cache == true
                        
                        -- Only log safe value if session is supported AND safe value is not $0
                        -- (Don't spam $0 values in unsupported sessions)
                        if session_supported and current_safe > 0 then
                            log.info(LOG_PREFIX .. "Agency Safe: $" .. format_money(current_safe))
                        
                            -- If safe reached capacity, collect it
                            if current_safe >= SAFE_CAPACITY then
                                local collected = collect_agency_earnings(current_safe)
                                if collected > 0 then
                                    total_collected = total_collected + collected
                                    collection_count = collection_count + 1
                                    -- Reset payout tracking after collection
                                    payout_attempts_without_increase = 0
                                    last_safe_value_before_payout = nil
                                end
                                script.yield(2000) -- Wait for collection to process
                            end
                        end
                    end
                else
                    log.info("============ *DETECTED PENDING TRANSACTIONS* =============")
                    wait_for_transaction()
                end
            
                -- Increment payout tick counter
                payout_tick_count = payout_tick_count + 1
                total_payout_ticks = total_payout_ticks + 1  -- Never reset, for time calculation
                
                -- Check if 5 minutes have passed for stats display (approximately)
                if payout_tick_count >= STATS_TICK_THRESHOLD then
                    if session_supported then
                        log.info("==========================================================")
                        log.info("================ Agency Stats (5 Minutes) ================")
                        log.info(LOG_PREFIX .. "Total Collected: $" .. format_money(total_collected))
                        log.info(LOG_PREFIX .. "Total Collections: " .. tostring(collection_count))
                        
                        
                        -- Calculate collections per hour based on total runtime
                        if total_payout_ticks > 0 then
                            local total_hours = (total_payout_ticks * 7.1) / 3600  -- Convert seconds to hours
                            if total_hours > 0 then
                                local collections_per_hour = math.floor(collection_count / total_hours)
                                log.info(LOG_PREFIX .. "Collections Per Hour: " .. tostring(collections_per_hour))
                                log.info("==========================================================")
                            end
                        end
                    end
                    -- Reset only the tick counter for next 5-minute interval
                    payout_tick_count = 0
                end
            end
            
            -- Wait before restarting
            script.yield(2000)
        end
    end
end)
