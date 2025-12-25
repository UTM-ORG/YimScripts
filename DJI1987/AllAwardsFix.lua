-- Original TinkerScript by ImagineNothing
-- Redesigned by DJ1987 with transaction-first architecture and adaptive rate limiting
script.run_in_callback(function()
    log.info("==========================================================")
    log.info("========== TinkerScript - Unlock Rewards Loaded ==========")
    log.info("==========================================================")
    
    -- ===== PHASE 1: Transaction-First Initialization =====
    -- CRITICAL: Wait for any pending transactions FIRST before doing anything
    local function is_transaction_pending_safe()
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
    
    local function wait_for_transaction_safe(timeout_ms)
        timeout_ms = timeout_ms or 10000
        local max_iterations = math.floor(timeout_ms / 100)
        local iterations = 0
        
        while is_transaction_pending_safe() do
            if iterations >= max_iterations then
                return false
            end
            iterations = iterations + 1
            script.yield(100)
        end
        return true
    end
    
    -- Wait for transactions to clear before doing anything
    if is_transaction_pending_safe() then
        log.info("Waiting for pending transactions before initialization...")
        wait_for_transaction_safe(15000)
    end
    
    -- Small delay to ensure session is stable
    script.yield(1000)
    
    -- Load natives if available (after transaction check)
    if natives and natives.load_natives then
        local ok, err = pcall(function()
            natives.load_natives()
        end)
        if not ok then
            log.warn("Failed to load natives: " .. tostring(err))
        end
    end
    
    -- Check if freemode script is running (single player detection)
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
    
    -- Wait for freemode script to start (multiplayer)
    if not freemode_running then
        log.warn("====== DETECTED: Singleplayer - Waiting for Online =======")
        notify.warn("UnlockAll-Rewards", "Singleplayer Detected\nPlease join an online session")
        
        while not freemode_running do
            script.yield(1000)
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
        log.info("=== DETECTED: Online - Starting Unlock Rewards Script ====")
        notify.info("UnlockAll-Rewards", "Online session detected\nStarting script...")
    end
    
    local is_online = freemode_running
    
    if is_online then
        -- Ensure transactions are clear before proceeding
        if is_transaction_pending_safe() then
            log.info("Transactions detected, waiting before starting...")
            wait_for_transaction_safe(15000)
        end
        
        notify.info("Script - All Awards Only", "Original TinkerScript by ImagineNothing\nRedesigned with transaction-first architecture")
        
        -- ===== Configuration =====
        -- Adaptive rate limiting - optimized for speed while maintaining transaction safety
        local BASE_DELAY_MS = 200  -- Base delay between operations (0.2 seconds) - reduced for speed
        local MIN_DELAY_MS = 100  -- Minimum delay (0.1 seconds) - reduced for speed
        local MAX_DELAY_MS = 2000  -- Maximum delay (2 seconds) - reduced but still allows backoff
        local CURRENT_DELAY_MS = BASE_DELAY_MS  -- Current adaptive delay
        local TRANSACTION_WAIT_TIMEOUT_MS = 30000
        local MAX_RETRIES = 2
        local RETRY_DELAY_MS = 1000  -- Reduced retry delay for faster recovery
        local PROGRESS_NOTIFICATION_INTERVAL = 10  -- Show notification every 10% progress
        local INITIAL_DELAY_MS = 500  -- Reduced initial delay (0.5 seconds)
        
        -- Cache function references
        local netshopping_is_session_refresh_pending = nil
        local ok_cache, _ = pcall(function()
            if type(NETSHOPPING) == "table" then
                netshopping_is_session_refresh_pending = NETSHOPPING["NET_GAMESERVER_IS_SESSION_REFRESH_PENDING"]
            end
        end)
        
        -- Transaction management
        local function is_transaction_pending()
            local ok, pending = pcall(function()
                if netshopping_is_session_refresh_pending and type(netshopping_is_session_refresh_pending) == "function" then
                    return netshopping_is_session_refresh_pending()
                end
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
        
        local function wait_for_transaction(timeout_ms)
            timeout_ms = timeout_ms or TRANSACTION_WAIT_TIMEOUT_MS
            local max_iterations = math.floor(timeout_ms / 100)
            local iterations = 0
            
            while is_transaction_pending() do
                if iterations >= max_iterations then
                    log.warn("Transaction wait timeout - continuing anyway")
                    return false
                end
                iterations = iterations + 1
                script.yield(100)
            end
            return true
        end
        
        -- Adaptive delay adjustment based on transaction activity
        local function adjust_delay(had_transaction)
            if had_transaction then
                -- Increase delay if transaction occurred
                CURRENT_DELAY_MS = math.min(CURRENT_DELAY_MS + 200, MAX_DELAY_MS)
            else
                -- Gradually decrease delay if no transactions
                CURRENT_DELAY_MS = math.max(CURRENT_DELAY_MS - 50, MIN_DELAY_MS)
            end
        end
        
        -- Set stat with retry logic
        local function set_stat_with_retry(stat)
            local last_error = nil
            
            for attempt = 1, MAX_RETRIES do
                -- Wait for transactions before setting
                if is_transaction_pending() then
                    log.info("Waiting for pending transactions before setting " .. stat.name .. "...")
                    wait_for_transaction(10000)
                    if is_transaction_pending() then
                        last_error = "Transaction still pending after wait"
                        log.warn("Transaction still pending for " .. stat.name .. ", skipping...")
                        return false, last_error, true  -- Return true for had_transaction
                    end
                end
                
                -- Adaptive delay before setting stat
                script.yield(CURRENT_DELAY_MS)
                
                -- Double-check transactions
                if is_transaction_pending() then
                    last_error = "Transaction started during delay"
                    if attempt < MAX_RETRIES then
                        log.warn("Transaction detected during delay for " .. stat.name .. ", retrying...")
                        script.yield(RETRY_DELAY_MS)
                    else
                        return false, last_error, true
                    end
                else
                    -- Attempt to set the stat
                    local ok, err = pcall(function()
                        if stat.type == "int" then
                            stats.set_int(stat.name, stat.value)
                        elseif stat.type == "bool" then
                            stats.set_bool(stat.name, stat.value)
                        else
                            error("Unknown stat type: " .. tostring(stat.type))
                        end
                    end)
                    
                    if not ok then
                        last_error = err
                        if attempt < MAX_RETRIES then
                            log.warn("Attempt " .. tostring(attempt) .. " failed for " .. stat.name .. ", retrying...")
                            script.yield(RETRY_DELAY_MS)
                        end
                    else
                        -- Wait for server sync
                        script.yield(CURRENT_DELAY_MS)
                        
                        -- Check if transaction started after setting
                        local had_transaction = false
                        if is_transaction_pending() then
                            had_transaction = true
                            log.info("Transaction started after setting " .. stat.name .. ", waiting...")
                            wait_for_transaction(10000)
                        end
                        
                        return true, nil, had_transaction
                    end
                end
            end
            
            return false, last_error, false
        end
        
        -- Define all stats in a table structure
        local all_stats = {
            -- Victory
            {type = "int", name = "MPX_AWD_FM_DM_WINS", value = 50}, -- The Slayer
            {type = "int", name = "MPX_AWD_FM_TDM_WINS", value = 50}, -- Death Brigade
            {type = "int", name = "MPX_AWD_FM_TDM_MVP", value = 50}, -- Team Carrier
            {type = "int", name = "MPX_AWD_RACES_WON", value = 50}, -- The Champion
            {type = "int", name = "MPX_AWD_FMWINAIRRACE", value = 25}, -- The Aviator
            {type = "int", name = "MPX_AWD_FMWINSEARACE", value = 25}, -- Making Waves
            {type = "int", name = "MPX_AWD_FM_GTA_RACES_WON", value = 50}, -- Cruisin' for a Bruisin'
            {type = "bool", name = "MPX_AWD_FMKILL3ANDWINGTARACE", value = true}, -- Road Rage
            {type = "int", name = "MPX_AWD_FMRALLYWONDRIVE", value = 25}, -- Follow to a Tee
            {type = "int", name = "MPX_AWD_FMRALLYWONNAV", value = 25}, -- The Dictator
            {type = "int", name = "MPX_AWD_FMWINRACETOPOINTS", value = 25}, -- Impromptu Champion
            {type = "bool", name = "MPX_AWD_FMWINCUSTOMRACE", value = true}, -- In a Class of Your Own
            {type = "int", name = "MPX_AWD_FM_RACE_LAST_FIRST", value = 25}, -- Penetrate From Behind
            {type = "bool", name = "MPX_AWD_FMRACEWORLDRECHOLDER", value = true}, -- The Record Holder
            {type = "int", name = "MPX_AWD_FM_RACES_FASTEST_LAP", value = 50}, -- Dust Maker
            {type = "bool", name = "MPX_AWD_FMWINALLRACEMODES", value = true}, -- Every Race
            {type = "int", name = "MPX_AWD_FMHORDWAVESSURVIVE", value = 10}, -- Survivor
            {type = "int", name = "MPX_MOST_ARM_WRESTLING_WINS", value = 25}, -- Over the Top
            {type = "int", name = "MPX_AWD_WIN_AT_DARTS", value = 25}, -- Throwback King
            {type = "int", name = "MPX_AWD_FM_GOLF_WON", value = 25}, -- The Swing King
            {type = "int", name = "MPX_AWD_FM_TENNIS_WON", value = 25}, -- Stroke Master
            {type = "bool", name = "MPX_AWD_FM_TENNIS_5_SET_WINS", value = true}, -- Out of Five
            {type = "bool", name = "MPX_AWD_FM_TENNIS_STASETWIN", value = true}, -- Straight Sets
            {type = "int", name = "MPX_AWD_FM_SHOOTRANG_TG_WON", value = 25}, -- Crack Shot
            {type = "int", name = "MPX_AWD_FM_SHOOTRANG_CT_WON", value = 25}, -- Duck and Cover
            {type = "bool", name = "MPX_AWD_FM_SHOOTRANG_GRAN_WON", value = true}, -- Granny
            {type = "int", name = "MPX_AWD_FM_SHOOTRANG_RT_WON", value = 25}, -- The Marksman
            {type = "bool", name = "MPX_AWD_FMWINEVERYGAMEMODE", value = true}, -- All Rounder
            {type = "int", name = "MPX_AWD_WIN_CAPTURES", value = 50}, -- Captured
            {type = "int", name = "MPX_AWD_WIN_CAPTURE_DONT_DYING", value = 25}, -- Death Defying
            {type = "int", name = "MPX_AWD_WIN_LAST_TEAM_STANDINGS", value = 50}, -- Still Standing
            {type = "int", name = "MPX_AWD_ONLY_PLAYER_ALIVE_LTS", value = 50}, -- One and Only
            {type = "int", name = "MPX_AWD_KILL_TEAM_YOURSELF_LTS", value = 25}, -- One Man Army
            -- General
            {type = "bool", name = "MPX_AWD_FM25DIFFERENTDM", value = true}, -- War Pig
            {type = "bool", name = "MPX_AWD_FM25DIFFERENTRACES", value = true}, -- Veteran Racer
            {type = "int", name = "MPX_AWD_PARACHUTE_JUMPS_20M", value = 25}, -- Nick of Time
            {type = "int", name = "MPX_AWD_PARACHUTE_JUMPS_50M", value = 25}, -- Point Break
            {type = "int", name = "MPX_AWD_FMBASEJMP", value = 25}, -- Stayed on Target
            {type = "bool", name = "MPX_AWD_FMATTGANGHQ", value = true}, -- Clear Out
            {type = "bool", name = "MPX_AWD_FM6DARTCHKOUT", value = true}, -- Checking Out
            {type = "int", name = "MPX_AWD_FM_GOLF_BIRDIES", value = 25}, -- Birdies
            {type = "bool", name = "MPX_AWD_FM_GOLF_HOLE_IN_1", value = true}, -- Hole in One
            {type = "int", name = "MPX_AWD_FM_TENNIS_ACE", value = 25}, -- Ace
            {type = "int", name = "MPX_AWD_FMBBETWIN", value = 50000}, -- The Hustler
            {type = "int", name = "MPX_AWD_LAPDANCES", value = 25}, -- Lapping it Up
            {type = "bool", name = "MPX_AWD_FM25DIFITEMSCLOTHES", value = true}, -- Snappy Dresser
            {type = "int", name = "MPX_AWD_NO_HAIRCUTS", value = 25}, -- Hairy Encounters
            {type = "bool", name = "MPX_AWD_BUY_EVERY_GUN", value = true}, -- Proud Gun Owner
            {type = "bool", name = "MPX_AWD_FMTATTOOALLBODYPARTS", value = true}, -- The Human Canvas
            {type = "int", name = "MPPLY_AWD_FM_CR_DM_MADE", value = 25}, -- The Matchmaker*
            {type = "int", name = "MPPLY_AWD_FM_CR_RACES_MADE", value = 25}, -- Track Builder*
            {type = "int", name = "MPPLY_AWD_FM_CR_PLAYED_BY_PEEP", value = 100}, -- Reeling Them In*
            {type = "int", name = "MPPLY_AWD_FM_CR_MISSION_SCORE", value = 100}, -- Creator Mission Score*
            {type = "int", name = "MPX_AWD_DROPOFF_CAP_PACKAGES", value = 100}, -- The Postman
            {type = "int", name = "MPX_AWD_PICKUP_CAP_PACKAGES", value = 100}, -- Gimme That
            {type = "int", name = "MPX_AWD_MENTALSTATE_TO_NORMAL", value = 50}, -- Calm Down
            {type = "bool", name = "MPX_AWD_STORE_20_CAR_IN_GARAGES", value = true}, -- Showroom
            {type = "int", name = "MPX_AWD_TRADE_IN_YOUR_PROPERTY", value = 25}, -- Moving Day
            {type = "int", name = "MPX_COMPLETEDAILYOBJ", value = 100}, -- Daily Objectives Completed (current count)
            {type = "int", name = "MPX_COMPLETEDAILYOBJTOTAL", value = 100}, -- Total Daily Objectives Completed
            {type = "int", name = "MPX_TOTALDAYCOMPLETED", value = 100}, -- Total Days Completed
            {type = "int", name = "MPX_TOTALWEEKCOMPLETED", value = 400}, -- Total Weeks Completed
            {type = "int", name = "MPX_TOTALMONTHCOMPLETED", value = 1800}, -- Total Months Completed
            {type = "int", name = "MPX_CONSECUTIVEDAYCOMPLETED", value = 30}, -- Consecutive Days Completed
            {type = "int", name = "MPX_CONSECUTIVEWEEKCOMPLETED", value = 4}, -- Consecutive Weeks Completed
            {type = "int", name = "MPX_CONSECUTIVEMONTHCOMPLETE", value = 1}, -- Consecutive Months Completed
            {type = "int", name = "MPX_COMPLETEDAILYOBJSA", value = 100}, -- Daily Objectives Completed SA (Story/Adversary mode)
            {type = "int", name = "MPX_COMPLETEDAILYOBJTOTALSA", value = 100}, -- Total Daily Objectives Completed SA
            {type = "int", name = "MPX_TOTALDAYCOMPLETEDSA", value = 100}, -- Total Days Completed SA
            {type = "int", name = "MPX_TOTALWEEKCOMPLETEDSA", value = 400}, -- Total Weeks Completed SA
            {type = "int", name = "MPX_TOTALMONTHCOMPLETEDSA", value = 1800}, -- Total Months Completed SA
            {type = "int", name = "MPX_CONSECUTIVEDAYCOMPLETEDSA", value = 30}, -- Consecutive Days Completed SA
            {type = "int", name = "MPX_CONSECUTIVEWEEKCOMPLETEDSA", value = 4}, -- Consecutive Weeks Completed SA
            {type = "int", name = "MPX_CONSECUTIVEMONTHCOMPLETESA", value = 1}, -- Consecutive Months Completed SA
            {type = "int", name = "MPX_AWD_DAILYOBJCOMPLETED", value = 100}, -- Daily Duty
            {type = "int", name = "MPX_AWD_DAILYOBJCOMPLETEDSA", value = 100}, -- Daily Duty SA (Story/Adversary mode)
            {type = "bool", name = "MPX_AWD_DAILYOBJWEEKBONUS", value = true}, -- Goal Oriented
            {type = "bool", name = "MPX_AWD_DAILYOBJWEEKBONUSSA", value = true}, -- Goal Oriented SA (Story/Adversary mode)
            {type = "bool", name = "MPX_AWD_DAILYOBJMONTHBONUS", value = true}, -- Over Achiever
            {type = "bool", name = "MPX_AWD_DAILYOBJMONTHBONUSSA", value = true}, -- Over Achiever SA (Story/Adversary mode)
            -- Crimes
            {type = "int", name = "MPX_CHAR_WANTED_LEVEL_TIME5STAR", value = 7200000}, -- The Fugitive
            {type = "int", name = "MPX_AWD_5STAR_WANTED_AVOIDANCE", value = 50}, -- The Police Mocker
            {type = "int", name = "MPX_AWD_FMSHOOTDOWNCOPHELI", value = 25}, -- When Pigs Can Fly
            {type = "int", name = "MPX_PASS_DB_PLAYER_KILLS", value = 100}, -- Death by Drive-By
            {type = "int", name = "MPX_NUMBER_STOLEN_CARS", value = 500}, -- Vehicle Thief
            {type = "int", name = "MPX_AWD_HOLD_UP_SHOPS", value = 20}, -- Armed Robber
            -- Vehicles
            {type = "int", name = "MPX_CARS_EXPLODED", value = 500}, -- Sky High
            {type = "int", name = "MPX_AWD_CARS_EXPORTED", value = 50}, -- The Exporter
            {type = "int", name = "MPX_AWD_FMDRIVEWITHOUTCRASH", value = 30}, -- No Claims Bonus
            {type = "int", name = "MPX_AWD_PASSENGERTIME", value = 4}, -- The Passenger
            {type = "int", name = "MPX_AWD_TIME_IN_HELICOPTER", value = 4}, -- Mile High Club
            {type = "bool", name = "MPX_AWD_FMFULLYMODDEDCAR", value = true}, -- Suped Up
            {type = "int", name = "MPX_AIR_LAUNCHES_OVER_40M", value = 25}, -- Airborne
            {type = "int", name = "MPX_MOST_FLIPS_IN_ONE_JUMP", value = 5}, -- Flippin' Hell
            {type = "int", name = "MPX_MOST_SPINS_IN_ONE_JUMP", value = 5}, -- Spinderella
            {type = "bool", name = "MPX_AWD_FMFURTHESTWHEELIE", value = true}, -- Unirider
            -- Combat
            {type = "int", name = "MPX_AWD_100_HEADSHOTS", value = 500}, -- Head Banger
            {type = "int", name = "MPX_KILLS_PLAYERS", value = 1000}, -- The Widow Maker
            {type = "int", name = "MPX_AWD_FMKILLBOUNTY", value = 25}, -- The Bounty Hunter
            {type = "int", name = "MPX_AWD_FMREVENGEKILLSDM", value = 50}, -- The Equalizer
            {type = "int", name = "MPX_AWD_FM_DM_KILLSTREAK", value = 100}, -- Streaker
            {type = "int", name = "MPX_AWD_FM_DM_STOLENKILL", value = 50}, -- Stolen Kills
            {type = "int", name = "MPX_AWD_FM_DM_TOTALKILLS", value = 500}, -- Death Toll
            {type = "bool", name = "MPX_AWD_FMKILLSTREAKSDM", value = true}, -- Killstreaker
            {type = "bool", name = "MPX_AWD_FMMOSTKILLSGANGHIDE", value = true}, -- Smoke 'Em Out
            {type = "bool", name = "MPX_AWD_FMMOSTKILLSSURVIVE", value = true}, -- Bloodiest of the Bunch
            {type = "int", name = "MPX_AWD_FM_DM_3KILLSAMEGUY", value = 50}, -- 3 for 1
            {type = "int", name = "MPX_AWD_KILL_CARRIER_CAPTURE", value = 100}, -- No You Don't
            {type = "int", name = "MPX_AWD_NIGHTVISION_KILLS", value = 100}, -- Lights Out
            {type = "int", name = "MPX_AWD_KILL_PSYCHOPATHS", value = 100}, -- Psycho Killer
            {type = "int", name = "MPX_PISTOL50_ENEMY_KILLS", value = 500}, -- Pistol Whipped
            {type = "int", name = "MPX_AWD_100_KILLS_SMG", value = 500}, -- SMG Head
            {type = "int", name = "MPX_ASLTSHTGN_ENEMY_KILLS", value = 500}, -- Shotgun Blues
            {type = "int", name = "MPX_ASLTRIFLE_ENEMY_KILLS", value = 500}, -- Looking Down the Barrel
            {type = "int", name = "MPX_SNIPERRFL_ENEMY_KILLS", value = 100}, -- Scoping Out
            {type = "int", name = "MPX_CMBTMG_ENEMY_KILLS", value = 500}, -- Rapid Fire
            {type = "int", name = "MPX_AWD_25_KILLS_STICKYBOMBS", value = 50}, -- Ended in A Sticky Situation
            {type = "int", name = "MPX_GRENADE_ENEMY_KILLS", value = 50}, -- Grenade Fiend
            {type = "int", name = "MPX_RPG_ENEMY_KILLS", value = 500}, -- The Rocket Man
            {type = "int", name = "MPX_UNARMED_ENEMY_KILLS", value = 50}, -- The Melee Murderer
            {type = "int", name = "MPX_AWD_CAR_BOMBS_ENEMY_KILLS", value = 25}, -- The Car Bomber
            -- Heists
            {type = "int", name = "MPX_AWD_FINISH_HEISTS", value = 50}, -- The Big Time
            {type = "int", name = "MPX_AWD_FINISH_HEIST_SETUP_JOB", value = 50}, -- Be Prepared
            {type = "bool", name = "MPX_AWD_FINISH_HEIST_NO_DAMAGE", value = true}, -- Can't Touch This
            {type = "int", name = "MPX_AWD_WIN_GOLD_MEDAL_HEISTS", value = 25}, -- Decorated
            {type = "int", name = "MPX_AWD_DO_HEIST_AS_MEMBER", value = 25}, -- For Hire
            {type = "int", name = "MPX_AWD_DO_HEIST_AS_THE_LEADER", value = 25}, -- Shot Caller
            {type = "bool", name = "MPX_AWD_SPLIT_HEIST_TAKE_EVENLY", value = true}, -- Four Way
            {type = "bool", name = "MPX_AWD_ACTIVATE_2_PERSON_KEY", value = true}, -- It Takes Two
            {type = "int", name = "MPX_AWD_CONTROL_CROWDS", value = 25}, -- In Control
            {type = "bool", name = "MPX_AWD_ALL_ROLES_HEIST", value = true}, -- Jack of All Trades
            {type = "bool", name = "MPPLY_AWD_FLEECA_FIN", value = true}, -- Head for Heists*
            {type = "bool", name = "MPPLY_AWD_PRISON_FIN", value = true}, -- Go To Jail*
            {type = "bool", name = "MPPLY_AWD_HUMANE_FIN", value = true}, -- Lab Report*
            {type = "bool", name = "MPPLY_AWD_SERIESA_FIN", value = true}, -- Product Placement*
            {type = "bool", name = "MPPLY_AWD_PACIFIC_FIN", value = true}, -- Smooth Sailing*
            {type = "bool", name = "MPPLY_AWD_HST_ORDER", value = true}, -- All In Order*
            {type = "bool", name = "MPPLY_AWD_HST_SAME_TEAM", value = true}, -- Loyalty*
            {type = "bool", name = "MPPLY_AWD_HST_ULT_CHAL", value = true}, -- Criminal Mastermind*
            {type = "bool", name = "MPPLY_AWD_COMPLET_HEIST_MEM", value = true}, -- upporting Role*
            {type = "bool", name = "MPPLY_AWD_COMPLET_HEIST_1STPER", value = true}, -- Another Perspective*
            -- The Doomsday Heist
            {type = "bool", name = "MPPLY_AWD_GANGOPS_IAA", value = true}, -- Act I*
            {type = "bool", name = "MPPLY_AWD_GANGOPS_SUBMARINE", value = true}, -- Act II*
            {type = "bool", name = "MPPLY_AWD_GANGOPS_MISSILE", value = true}, -- Act III*
            {type = "bool", name = "MPPLY_AWD_GANGOPS_ALLINORDER", value = true}, -- All In Order II*
            {type = "bool", name = "MPPLY_AWD_GANGOPS_LOYALTY", value = true}, -- Loyalty II*
            {type = "bool", name = "MPPLY_AWD_GANGOPS_LOYALTY2", value = true}, -- Loyalty III*
            {type = "bool", name = "MPPLY_AWD_GANGOPS_LOYALTY3", value = true}, -- Loyalty IV*
            {type = "bool", name = "MPPLY_AWD_GANGOPS_CRIMMASMD", value = true}, -- Criminal Mastermind II*
            {type = "bool", name = "MPPLY_AWD_GANGOPS_CRIMMASMD2", value = true}, -- Criminal Mastermind III*
            {type = "bool", name = "MPPLY_AWD_GANGOPS_CRIMMASMD3", value = true}, -- Criminal Mastermind IV*
            {type = "bool", name = "MPPLY_AWD_GANGOPS_SUPPORT", value = true}, -- Supporting Role II*
            -- After Hours
            {type = "int", name = "MPX_AWD_CLUB_DRUNK", value = 200}, -- Club Drunk
            {type = "int", name = "MPX_DANCEPERFECTOWNCLUB", value = 100}, -- Coordinated
            {type = "int", name = "MPX_NIGHTCLUB_PLAYER_APPEAR", value = 500}, -- Hot Spot
            {type = "int", name = "MPX_AWD_DANCE_TO_SOLOMUN", value = 100}, -- Solomun 25/8
            {type = "int", name = "MPX_AWD_DANCE_TO_TALEOFUS", value = 100}, -- AFTERLIGHT
            {type = "int", name = "MPX_AWD_DANCE_TO_DIXON", value = 100}, -- Wilderness
            {type = "int", name = "MPX_AWD_DANCE_TO_BLKMAD", value = 100}, -- We Believe
            {type = "int", name = "MPX_DANCETODIFFDJS", value = 4}, -- Clubber
            -- Arena War --
            {type = "int", name = "MPX_AWD_CAREER_WINNER", value = 1000}, -- Career Winner
            {type = "int", name = "MPX_AWD_TOP_SCORE", value = 500000}, -- Top Score
            {type = "int", name = "MPX_AWD_TIME_SERVED", value = 1000}, -- Time Served
            {type = "int", name = "MPX_AWD_ARENA_WAGEWORKER", value = 20000000}, -- Arena Wageworker
            {type = "int", name = "MPX_AWD_WEVE_GOT_ONE", value = 50}, -- We've Got One!
            {type = "int", name = "MPX_AWD_YOURE_OUTTA_HERE", value = 200}, -- You're Outta Here!
            {type = "int", name = "MPX_AWD_MASSIVE_SHUNT", value = 50}, -- Massive Shunt
            {type = "int", name = "MPX_AWD_KILL_OR_BE_KILLED", value = 50}, -- Kill Or Be Killed
            {type = "int", name = "MPX_AWD_CROWDPARTICIPATION", value = 50}, -- Crowd Participation
            {type = "int", name = "MPX_AWD_SITTING_DUCK", value = 50}, -- Sitting Duck
            {type = "int", name = "MPX_AWD_YOUMEANBOOBYTRAPS", value = 50}, -- You Mean Booby Traps?
            {type = "int", name = "MPX_AWD_MASTER_BANDITO", value = 50}, -- Master Bandito
            {type = "int", name = "MPX_AWD_SPINNER", value = 50}, -- Spinner
            {type = "int", name = "MPX_AWD_THROUGH_A_LENS", value = 50}, -- Through a Lens
            {type = "int", name = "MPX_AWD_READY_FOR_WAR", value = 50}, -- Ready For War
            {type = "bool", name = "MPX_AWD_UNSTOPPABLE", value = true}, -- Unstoppable
            {type = "bool", name = "MPX_AWD_CONTACT_SPORT", value = true}, -- Contact Sports
            {type = "int", name = "MPX_AWD_TOWER_OFFENSE", value = 50}, -- Tower Offense
            {type = "int", name = "MPX_AWD_WATCH_YOUR_STEP", value = 50}, -- Watch Your Step
            {type = "bool", name = "MPX_AWD_PEGASUS", value = true}, -- Pegasus
            {type = "bool", name = "MPX_AWD_BEGINNER", value = true}, -- New Kid
            {type = "bool", name = "MPX_AWD_FIELD_FILLER", value = true}, -- Field-Filler
            {type = "bool", name = "MPX_AWD_ARMCHAIR_RACER", value = true}, -- Armchair Racer
            {type = "bool", name = "MPX_AWD_LEARNER", value = true}, -- Learner
            {type = "bool", name = "MPX_AWD_SUNDAY_DRIVER", value = true}, -- Gifted Amateur
            {type = "bool", name = "MPX_AWD_THE_ROOKIE", value = true}, -- The Rookie
            {type = "bool", name = "MPX_AWD_BUMP_AND_RUN", value = true}, -- Bump & Run
            {type = "bool", name = "MPX_AWD_GEAR_HEAD", value = true}, -- Gear-Head
            {type = "bool", name = "MPX_AWD_DOOR_SLAMMER", value = true}, -- Pinball
            {type = "bool", name = "MPX_AWD_HOT_LAP", value = true}, -- Semi-Pro
            {type = "bool", name = "MPX_AWD_ARENA_AMATEUR", value = true}, -- Arena Vet
            {type = "bool", name = "MPX_AWD_PAINT_TRADER", value = true}, -- Paint Trader
            {type = "bool", name = "MPX_AWD_SHUNTER", value = true}, -- Shunter
            {type = "bool", name = "MPX_AWD_JOCK", value = true}, -- Jock
            {type = "bool", name = "MPX_AWD_WARRIOR", value = true}, -- Wrecking Ball
            {type = "bool", name = "MPX_AWD_T_BONE", value = true}, -- First in Field
            {type = "bool", name = "MPX_AWD_MAYHEM", value = true}, -- Gladiator
            {type = "bool", name = "MPX_AWD_WRECKER", value = true}, -- Ring Master
            {type = "bool", name = "MPX_AWD_CRASH_COURSE", value = true}, -- Arena Warrior
            {type = "bool", name = "MPX_AWD_ARENA_LEGEND", value = true}, -- Arena Legend
            -- The Diamond Casino & Resort
            {type = "bool", name = "MPX_AWD_FIRST_TIME1", value = true}, -- Loose Cheng
            {type = "bool", name = "MPX_AWD_FIRST_TIME2", value = true}, -- House Keeping
            {type = "bool", name = "MPX_AWD_FIRST_TIME3", value = true}, -- Strong Arm Tactics
            {type = "bool", name = "MPX_AWD_FIRST_TIME4", value = true}, -- Play to Win
            {type = "bool", name = "MPX_AWD_FIRST_TIME5", value = true}, -- Bad Beat
            {type = "bool", name = "MPX_AWD_FIRST_TIME6", value = true}, -- Cashing Out
            {type = "bool", name = "MPX_AWD_ALL_IN_ORDER", value = true}, -- Straight
            {type = "bool", name = "MPX_AWD_SURVIVALIST", value = true}, -- Lucky Lucky
            {type = "bool", name = "MPX_AWD_SUPPORTING_ROLE", value = true}, -- Top Pair
            {type = "bool", name = "MPX_AWD_LEADER", value = true}, -- Full House
            {type = "int", name = "MPX_AWD_ODD_JOBS", value = 50}, -- High Roller
            -- Diamond Casino Heist
            {type = "bool", name = "MPX_AWD_SCOPEOUT", value = true}, -- Scope Out
            {type = "int", name = "MPX_AWD_PREPARATION", value = 40}, -- Preparation
            {type = "bool", name = "MPX_AWD_CREWEDUP", value = true}, -- All Crewed Up
            {type = "bool", name = "MPX_AWD_MOVINGON", value = true}, -- Moving On
            {type = "bool", name = "MPX_AWD_PROMOCAMP", value = true}, -- After Party
            {type = "bool", name = "MPX_AWD_GUNMAN", value = true}, -- Gunman
            {type = "bool", name = "MPX_AWD_SMASHNGRAB", value = true}, -- Smash & Grab
            {type = "bool", name = "MPX_AWD_INPLAINSI", value = true}, -- Hidden In Plain Sight
            {type = "bool", name = "MPX_AWD_UNDETECTED", value = true}, -- Undetected
            {type = "bool", name = "MPX_AWD_ALLROUND", value = true}, -- All Rounder
            {type = "bool", name = "MPX_AWD_ELITETHEIF", value = true}, -- Elite Thief
            {type = "bool", name = "MPX_AWD_PRO", value = true}, -- Professional
            {type = "bool", name = "MPX_AWD_SUPPORTACT", value = true}, -- Support Act
            {type = "bool", name = "MPX_AWD_SHAFTED", value = true}, -- Shafted
            {type = "int", name = "MPX_AWD_ASLEEPONJOB", value = 20}, -- Asleep On The Job
            {type = "int", name = "MPX_AWD_DAICASHCRAB", value = 100000}, -- Daily Cash Grab
            {type = "int", name = "MPX_AWD_BIGBRO", value = 40}, -- Big Brother
            {type = "bool", name = "MPX_AWD_COLLECTOR", value = true}, -- Collector
            {type = "bool", name = "MPX_AWD_DEADEYE", value = true}, -- Dead Eye
            {type = "bool", name = "MPX_AWD_PISTOLSATDAWN", value = true}, -- Pistols At Dawn
            {type = "int", name = "MPX_AWD_SHARPSHOOTER", value = 40}, -- Sharpshooter
            {type = "int", name = "MPX_AWD_RACECHAMP", value = 40}, -- Race Champion
            {type = "bool", name = "MPX_AWD_TRAFFICAVOI", value = true}, -- Beat The Traffic
            {type = "bool", name = "MPX_AWD_CANTCATCHBRA", value = true}, -- All Wheels
            {type = "bool", name = "MPX_AWD_WIZHARD", value = true}, -- Feelin' Groggy
            {type = "int", name = "MPX_AWD_BATSWORD", value = 1000000}, -- Platinum Sword
            {type = "int", name = "MPX_AWD_COINPURSE", value = 950000}, -- Coin Purse
            {type = "bool", name = "MPX_AWD_APEESCAPE", value = true}, -- Ape Escape
            {type = "bool", name = "MPX_AWD_MONKEYKIND", value = true}, -- Monkey Mind
            {type = "int", name = "MPX_AWD_ASTROCHIMP", value = 3000000}, -- Astrochimp
            {type = "bool", name = "MPX_AWD_AQUAAPE", value = true}, -- Aquatic Ape
            {type = "bool", name = "MPX_AWD_KEEPFAITH", value = true}, -- Keeping The Faith
            {type = "int", name = "MPX_AWD_MASTERFUL", value = 40000}, -- Masterful
            {type = "bool", name = "MPX_AWD_TRUELOVE", value = true}, -- True Love
            {type = "bool", name = "MPX_AWD_NEMESIS", value = true}, -- Nemesis
            {type = "bool", name = "MPX_AWD_FRIENDZONED", value = true}, -- Friendzoned
            -- Los Santos Summer Special
            {type = "bool", name = "MPX_AWD_KINGOFQUB3D", value = true}, -- King Of QUB3D
            {type = "bool", name = "MPX_AWD_QUBISM", value = true}, -- Qubism
            {type = "bool", name = "MPX_AWD_GODOFQUB3D", value = true}, -- God Of QUB3D
            {type = "bool", name = "MPX_AWD_QUIBITS", value = true}, -- Qubits
            {type = "bool", name = "MPX_AWD_ELEVENELEVEN", value = true}, -- 11 11
            {type = "bool", name = "MPX_AWD_GOFOR11TH", value = true}, -- Crank It To 11
            -- The Cayo Perico Heist
            {type = "bool", name = "MPX_AWD_INTELGATHER", value = true}, -- In and Out
            {type = "bool", name = "MPX_AWD_COMPOUNDINFILT", value = true}, -- Easy Access
            {type = "int", name = "MPX_AWD_WELL_PREPARED", value = 50}, -- Prepped
            {type = "bool", name = "MPX_AWD_LOOT_FINDER", value = true}, -- It's a Steal
            {type = "bool", name = "MPX_AWD_MAX_DISRUPT", value = true}, -- Maximum Disruption
            {type = "bool", name = "MPX_AWD_THE_ISLAND_HEIST", value = true}, -- The Cayo Perico Heist
            {type = "bool", name = "MPX_AWD_GOING_ALONE", value = true}, -- Going Alone
            {type = "bool", name = "MPX_AWD_TEAM_WORK", value = true}, -- Teamwork
            {type = "bool", name = "MPX_AWD_MIXING_UP", value = true}, -- Travel Plans
            {type = "bool", name = "MPX_AWD_PRO_THIEF", value = true}, -- Professional Thief
            {type = "bool", name = "MPX_AWD_CAT_BURGLAR", value = true}, -- Cat Burglar
            {type = "bool", name = "MPX_AWD_ONE_OF_THEM", value = true}, -- One of Them
            {type = "int", name = "MPX_AWD_FILL_YOUR_BAGS", value = 20000000}, -- Fill Your Bags
            {type = "bool", name = "MPX_AWD_GOLDEN_GUN", value = true}, -- Go For Gold
            {type = "bool", name = "MPX_AWD_ELITE_THIEF", value = true}, -- Elitist
            {type = "bool", name = "MPX_AWD_PROFESSIONAL", value = true}, -- Blow Hard
            {type = "int", name = "MPX_AWD_WRECK_DIVING", value = 1000000}, -- Wreck Diving
            {type = "bool", name = "MPX_AWD_PARTY_VIBES", value = true}, -- Party Vibes
            {type = "int", name = "MPX_AWD_SUNSET", value = 1800000}, -- Sun Set
            {type = "bool", name = "MPX_AWD_HELPING_HAND", value = true}, -- Helping Hand
            {type = "int", name = "MPX_AWD_MOODYMANN", value = 1800000}, -- Moodymann
            {type = "int", name = "MPX_AWD_PALMS_TRAX", value = 1800000}, -- Palms Trax
            {type = "bool", name = "MPX_AWD_HELPING_OUT", value = true}, -- Helping Out
            {type = "int", name = "MPX_AWD_KEINEMUSIK", value = 1800000}, -- Keinemusik
            {type = "bool", name = "MPX_AWD_COURIER", value = true}, -- Courier
            {type = "int", name = "MPX_AWD_TREASURE_HUNTER", value = 50}, -- Treasure Hunter
            -- Los Santos Tuners
            {type = "bool", name = "MPX_AWD_CAR_CLUB", value = true}, -- LS Car Meet
            {type = "int", name = "MPX_AWD_CAR_CLUB_MEM", value = 1000}, -- LS Car Meet Member
            {type = "int", name = "MPX_AWD_SPRINTRACER", value = 50}, -- Sprint Racer
            {type = "int", name = "MPX_AWD_STREETRACER", value = 50}, -- Street Racer
            {type = "int", name = "MPX_AWD_PURSUITRACER", value = 50}, -- Pursuit Racer
            {type = "int", name = "MPX_AWD_TEST_CAR", value = 1800000}, -- Tried And Tested
            {type = "int", name = "MPX_AWD_AUTO_SHOP", value = 100}, -- Special Delivery
            {type = "int", name = "MPX_AWD_CAR_EXPORT", value = 100}, -- Car Exporter
            {type = "bool", name = "MPX_AWD_PRO_CAR_EXPORT", value = true}, -- Pro Car Exporter
            {type = "int", name = "MPX_AWD_GROUNDWORK", value = 250}, -- Groundwork
            {type = "bool", name = "MPX_AWD_UNION_DEPOSITORY", value = true}, -- The Union Depository Contract
            {type = "bool", name = "MPX_AWD_MILITARY_CONVOY", value = true}, -- The Superdollar Deal
            {type = "bool", name = "MPX_AWD_FLEECA_BANK", value = true}, -- The Bank Contract
            {type = "bool", name = "MPX_AWD_FREIGHT_TRAIN", value = true}, -- The ECU Contract
            {type = "bool", name = "MPX_AWD_BOLINGBROKE_[removed]", value = true}, -- The Prison Contract
            {type = "bool", name = "MPX_AWD_IAA_RAID", value = true}, -- The Agency Deal
            {type = "bool", name = "MPX_AWD_METH_JOB", value = true}, -- The Lost Contract
            {type = "bool", name = "MPX_AWD_BUNKER_RAID", value = true}, -- The Data Contract
            {type = "int", name = "MPX_AWD_ROBBERY_CONTRACT", value = 100}, -- Contractual Criminal
            {type = "int", name = "MPX_AWD_FACES_OF_DEATH", value = 100}, -- Faces Of Death
            {type = "bool", name = "MPX_AWD_STRAIGHT_TO_VIDEO", value = true}, -- Straight To Video
            {type = "bool", name = "MPX_AWD_MONKEY_C_MONKEY_DO", value = true}, -- Monkey See Monkey Do
            {type = "bool", name = "MPX_AWD_TRAINED_TO_KILL", value = true}, -- Trained to Kill
            {type = "bool", name = "MPX_AWD_DIRECTOR", value = true}, -- The Director
            -- The Contract
            {type = "bool", name = "MPX_AWD_TEEING_OFF", value = true}, -- On Course
            {type = "bool", name = "MPX_AWD_PARTY_NIGHT", value = true}, -- Nightlife Leak
            {type = "bool", name = "MPX_AWD_BILLIONAIRE_GAMES", value = true}, -- High Society Leak
            {type = "bool", name = "MPX_AWD_HOOD_PASS", value = true}, -- South Central Leak
            {type = "bool", name = "MPX_AWD_STUDIO_TOUR", value = true}, -- Studio Time
            {type = "bool", name = "MPX_AWD_DONT_MESS_DRE", value = true}, -- Don't [removed] With Dre
            {type = "bool", name = "MPX_AWD_BACKUP", value = true}, -- Backup
            {type = "bool", name = "MPX_AWD_SHORTFRANK_1", value = true}, -- Seed Capital - Franklin
            {type = "bool", name = "MPX_AWD_SHORTLAMAR_1", value = true}, -- Seed Capital - Lamar
            {type = "bool", name = "MPX_AWD_SHORTFRANK_2", value = true}, -- Fire It Up - Franklin
            {type = "bool", name = "MPX_AWD_SHORTLAMAR_2", value = true}, -- Fire It Up - Lamar
            {type = "bool", name = "MPX_AWD_SHORTFRANK_3", value = true}, -- OG Kush - Franklin
            {type = "bool", name = "MPX_AWD_SHORTLAMAR_3", value = true}, -- OG Kush - Lamar
            {type = "int", name = "MPX_AWD_CONTRACTOR", value = 50}, -- Contractual Obligations
            {type = "int", name = "MPX_AWD_COLD_CALLER", value = 50}, -- Cold Caller
            {type = "bool", name = "MPX_AWD_CONTR_KILLER", value = true}, -- Contract Killer
            {type = "bool", name = "MPX_AWD_DOGS_BEST_FRIEND", value = true}, -- A Dog's Best Friend
            {type = "bool", name = "MPX_AWD_MUSIC_STUDIO", value = true}, -- Sound Check
            {type = "int", name = "MPX_AWD_PRODUCER", value = 60}, -- Producer
            -- Los Santos Drug Wars
            {type = "bool", name = "MPX_AWD_ACELIQUOR", value = true}, -- Welcome to the Troupe
            {type = "bool", name = "MPX_AWD_TRUCKAMBUSH", value = true}, -- Designated Driver
            {type = "bool", name = "MPX_AWD_LOSTCAMPREV", value = true}, -- Fatal Incursion
            {type = "bool", name = "MPX_AWD_ACIDTRIP", value = true}, -- Uncontrolled Substance
            {type = "int", name = "MPX_AWD_RUNRABBITRUN", value = 5}, -- Run Rabbit Run
            {type = "bool", name = "MPX_AWD_HIPPYRIVALS", value = true}, -- Make War not Love
            {type = "bool", name = "MPX_AWD_TRAINCRASH", value = true}, -- Off The Rails
            {type = "int", name = "MPX_AWD_CALLME", value = 50}, -- Call Me
            {type = "bool", name = "MPX_AWD_BACKUPB", value = true}, -- Back It Up
            {type = "bool", name = "MPX_AWD_GETSTARTED", value = true}, -- Lick My Acid
            {type = "int", name = "MPX_AWD_CHEMCOMPOUNDS", value = 50}, -- Chemical Attraction
            {type = "bool", name = "MPX_AWD_CHEMREACTION", value = true}, -- Chemical Reaction
            {type = "int", name = "MPX_AWD_STASHHORAID", value = 50}, -- Stashes To Stashes
            {type = "int", name = "MPX_AWD_DEADDROP", value = 50}, -- Here Comes The Drop
            {type = "int", name = "MPX_AWD_GOODSAMARITAN", value = 50}, -- Good Samaritan
            {type = "bool", name = "MPX_AWD_WAREHODEFEND", value = true}, -- This Is An Intervention
            {type = "bool", name = "MPX_AWD_RESCUECOOK", value = true}, -- Unusual Suspects
            {type = "bool", name = "MPX_AWD_DRUGTRIPREHAB", value = true}, -- Fried Mind
            {type = "bool", name = "MPX_AWD_ATTACKINVEST", value = true}, -- Checking In
            {type = "int", name = "MPX_AWD_OWNWORSTENEMY", value = 60}, -- Your Own Worst Enemy
            {type = "bool", name = "MPX_AWD_CARGOPLANE", value = true}, -- BDKD
            {type = "bool", name = "MPX_AWD_BACKUPB2", value = true}, -- Back It Up 2
            {type = "int", name = "MPX_AWD_TAXIDRIVER", value = 50}, -- Taxi Driver
            {type = "bool", name = "MPX_AWD_TAXISTAR", value = true}, -- 5 Star Ride
            -- The Chop Shop
            {type = "bool", name = "MPX_AWD_MAZE_BANK_ROBBERY", value = true}, -- The Duggan Robbery
            {type = "bool", name = "MPX_AWD_CARGO_SHIP_ROBBERY", value = true}, -- The Cargo Ship Robbery
            {type = "bool", name = "MPX_AWD_MISSION_ROW_ROBBERY", value = true}, -- The [removed]er Robbery
            {type = "bool", name = "MPX_AWD_PERFECT_RUN", value = true}, -- Perfect Run
            {type = "bool", name = "MPX_AWD_EXTRA_MILE", value = true}, -- Extra Mile
            {type = "int", name = "MPX_AWD_VEHICLE_ROBBERIES", value = 50}, -- New Car Smell
            {type = "int", name = "MPX_AWD_PREP_WORK", value = 50}, -- Serious Prepper
            {type = "int", name = "MPX_AWD_CAR_DEALER", value = 5000000}, -- Wheeler Dealer
            {type = "int", name = "MPX_AWD_SECOND_HAND_PARTS", value = 5000000}, -- Second Hand Parts
            {type = "int", name = "MPX_AWD_TOW_TRUCK_SERVICE", value = 50}, -- Towed Away
            {type = "bool", name = "MPX_AWD_SUBMARINE_ROBBERY", value = true}, -- The McTony Robbery
            {type = "bool", name = "MPX_AWD_DIAMOND_CASINO_ROBBERY", value = true}, -- The Podium Robbery
            {type = "bool", name = "MPX_AWD_BOLINGBROKE", value = true}, -- Slush Fund
            {type = "bool", name = "MPX_AWD_GETTING_SET_UP", value = true}, -- Best Laid Plans
            {type = "bool", name = "MPX_AWD_CHICKEN_FACTORY_RAID", value = true}, -- The Cluckin' Bell Farm Raid
            {type = "bool", name = "MPX_AWD_HELPING_HAND2", value = true}, -- Pecking Order
            {type = "bool", name = "MPX_AWD_SURPRISE_ATTACK", value = true}, -- Sly Fox
            {type = "bool", name = "MPX_AWD_ALL_OUT_RAID", value = true}, -- [removed] Fight
            {type = "bool", name = "MPX_AWD_WEAPON_ARSENAL", value = true}, -- All The Sides
            {type = "bool", name = "MPX_AWD_GETAWAY_VEHICLES", value = true}, -- Fly The Coop
            -- Bottom Dollar Bounties
            {type = "bool", name = "MPX_AWD_HIVALBOUNT1", value = true}, -- Get Whitney
            {type = "bool", name = "MPX_AWD_HIVALBOUNT2", value = true}, -- Get Lieberman
            {type = "bool", name = "MPX_AWD_HIVALBOUNT3", value = true}, -- Get O'Neil
            {type = "bool", name = "MPX_AWD_HIVALBOUNT4", value = true}, -- Get Thompson
            {type = "bool", name = "MPX_AWD_HIVALBOUNT5", value = true}, -- Get Song
            {type = "bool", name = "MPX_AWD_HIVALBOUNT6", value = true}, -- Get Garcia
            {type = "int", name = "MPX_AWD_BOUNTIES", value = 50}, -- Bountiful
            {type = "int", name = "MPX_AWD_STANBOUNTIES", value = 50}, -- Still Breathing
            {type = "int", name = "MPX_AWD_BOUNTEARNS", value = 5000000}, -- Cash On Delivery
            {type = "int", name = "MPX_AWD_BAILOFFICSTAFF", value = 1000000}, -- Step Two: Profit
            {type = "int", name = "MPX_AWD_DISPATCHWORK", value = 50}, -- Dispatched
            {type = "int", name = "MPX_AWD_PIZZATHIS", value = 50}, -- Pizza This...
            {type = "bool", name = "MPX_AWD_ASSONATTACKSWIN", value = true}, -- Priority Boarding
            {type = "bool", name = "MPX_AWD_ASSONDEFENDWIN", value = true}, -- Not A Scratch
            {type = "int", name = "MPX_AWD_ASSONBONUSOBJ", value = 20}, -- Happy Landings
            {type = "int", name = "MPX_AWD_ASSONHARDDRIVE", value = 50}, -- Hard Drive Hoarder
            {type = "int", name = "MPX_AWD_FROSTBITE", value = 15}, -- Death Trap
            {type = "bool", name = "MPX_AWD_DISEASECONTROL", value = true}, -- One Of A Kind
            -- Agents of Sabotage
            {type = "bool", name = "MPX_AWD_FINEART", value = true}, -- The Fine Arts File
            {type = "bool", name = "MPX_AWD_BRUTEFORCE", value = true}, -- The Brute Force File
            {type = "bool", name = "MPX_AWD_PROJECTBREAK", value = true}, -- The Project Breakaway File
            {type = "bool", name = "MPX_AWD_BLACKBOXFILE", value = true}, -- The Black Box File
            {type = "bool", name = "MPX_AWD_BONUSPOINTS", value = true}, -- Bonus Points
            {type = "int", name = "MPX_AWD_DARNELLBROSINC", value = 50}, -- Darnell Bros Inc.
            {type = "int", name = "MPX_AWD_GET_READY", value = 50}, -- Get Ready
            {type = "int", name = "MPX_AWD_CASHINHAND", value = 5000000}, -- Cash In Hand
            {type = "int", name = "MPX_AWD_BROTHERLYLOVE", value = 50000}, -- Brotherly Love
            {type = "bool", name = "MPX_AWD_UPRUNNING", value = true}, -- Up And Running
            {type = "bool", name = "MPX_AWD_MOGUL", value = true}, -- Mogul
            {type = "bool", name = "MPX_AWD_INTEL", value = true}, -- Intel
            {type = "int", name = "MPX_AWD_NOTOUTDPT", value = 5}, -- Not Out Of Your Depth
            {type = "bool", name = "MPX_AWD_IRONMULE", value = true}, -- Iron Mule
            {type = "bool", name = "MPX_AWD_AMMUNITION", value = true}, -- Ammunition
            {type = "bool", name = "MPX_AWD_DIRDELIVERY", value = true}, -- Direct Delivery
            {type = "int", name = "MPX_AWD_FULSTOCKED", value = 8}, -- Fully Stocked
            {type = "bool", name = "MPX_AWD_TITANJOB", value = true}, -- The Titan Job
            {type = "bool", name = "MPX_AWD_PERMANENTCON", value = true}, -- Permanent Contract
            {type = "int", name = "MPX_AWD_ARMSINARMS", value = 50}, -- Arms In Arms
            -- Money Fronts
            {type = "bool", name = "MPX_AWD_JUNKSEARCH", value = true}, -- Liquid Market
            {type = "int", name = "MPX_AWD_DOGSDINNER", value = 5}, -- Dog's Dinner
            {type = "bool", name = "MPX_AWD_CASASS", value = true}, -- ROI
            {type = "bool", name = "MPX_AWD_LOCKUPINT", value = true}, -- Compound Interest
            {type = "bool", name = "MPX_AWD_ESCORTFLATBED", value = true}, -- Mutual Funds
            {type = "bool", name = "MPX_AWD_LEFT4DEAD", value = true}, -- Current Liabilities
            {type = "bool", name = "MPX_AWD_TRACKER", value = true}, -- Gut Instinct
            {type = "bool", name = "MPX_AWD_CLEARCOMP", value = true}, -- The Monopoly
            {type = "bool", name = "MPX_AWD_CASHBONUS", value = true}, -- Profit Maximization
            {type = "int", name = "MPX_AWD_HEATAROUDC", value = 25}, -- Licensed Professional
            {type = "int", name = "MPX_AWD_TYCOON", value = 2000000}, -- Cooking The Books
            {type = "bool", name = "MPX_AWD_BUSINEXPAND", value = true}, -- Diversification
            {type = "bool", name = "MPX_AWD_LOSTPRODUC", value = true}, -- Kush Collector
            {type = "int", name = "MPX_AWD_CASHCLEAN", value = 500000}, -- Squeaky Clean
            {type = "int", name = "MPX_AWD_MEDICOURI", value = 50}, -- QuickiePharm
            {type = "bool", name = "MPX_AWD_EMERGENCYSERV", value = true}, -- First Responder
            {type = "int", name = "MPX_AWD_TRANSPORT", value = 20}, -- Safeguard
            {type = "bool", name = "MPX_AWD_SECUREDEL", value = true}, -- Ironclad
            {type = "int", name = "MPX_AWD_SUNBURNED", value = 15}, -- Sunburned Survivor
            {type = "bool", name = "MPX_AWD_TWOOFAKIND", value = true}, -- The Indiscriminator
            {type = "int", name = "MPX_AWD_UNDEADPARTY", value = 60}, -- Dancing With Death
            -- A Safehouse in the Hills
            {type = "bool", name = "MPX_AWD_NEGATIVEPRESS", value = true}, -- Negative Press
            {type = "bool", name = "MPX_AWD_USESELFDRIVINGVEH", value = true}, -- Autonomous
            {type = "bool", name = "MPX_AWD_LIONSDEN", value = true}, -- Inside Job
            {type = "bool", name = "MPX_AWD_TAKEOUTLEADEXPLO", value = true}, -- Explosive Leadership
            {type = "bool", name = "MPX_AWD_SUBWAYTRAIN", value = true}, -- Tunnel Vision
            {type = "bool", name = "MPX_AWD_SUBWAYSTUNTJUMP", value = true}, -- Subway Stunt
            {type = "bool", name = "MPX_AWD_TRASHCOLLECTORS", value = true}, -- Trash Talking
            {type = "bool", name = "MPX_AWD_ALLTRASHCOLLECTED", value = true}, -- Waste Not
            {type = "bool", name = "MPX_AWD_FIBFINALE", value = true}, -- A Clean Break
            {type = "bool", name = "MPX_AWD_HELPER", value = true}, -- Willing Accomplice
            {type = "bool", name = "MPX_AWD_FIBFINALECHALLENGE", value = true}, -- The Cleanest Break
            {type = "bool", name = "MPX_AWD_MANSIONDEFEND", value = true}, -- Home Sweet Home
            {type = "bool", name = "MPX_AWD_DEFLOWMOTIONKILLS", value = true}, -- Dead Slow
            {type = "int", name = "MPX_AWD_TAXIDESTRUCTION", value = 20}, -- No Way KnoWay
            {type = "bool", name = "MPX_AWD_YOUVEMADEIT", value = true}, -- A place like this
            {type = "bool", name = "MPX_AWD_ANIMALLOVER", value = true}, -- Animal Instincts
            {type = "int", name = "MPX_AWD_YOGA", value = 50}, -- Namaste
            {type = "int", name = "MPX_AWD_JUICEDUP", value = 100}, -- Pumped
            {type = "int", name = "MPX_AWD_MANADVERSARYDEFUSE", value = 10}, -- Bomb Squad
            {type = "bool", name = "MPX_AWD_MANSADVERSARYWIN", value = true}, -- Mansion Raid
            {type = "int", name = "MPX_AWD_FIREFIGHTER", value = 20}, -- Knockdown
            {type = "int", name = "MPX_AWD_ALPHAMAIL", value = 20}, -- Alpha Mail
            {type = "int", name = "MPX_AWD_LOSSANTOSMETEOR", value = 20}, -- Meteoric
            {type = "bool", name = "MPX_AWD_ONTHECLOCK", value = true}, -- Hot Off The Press
        }
        
        -- ===== PHASE 2: Setting Phase =====
        -- Process all stats one at a time with adaptive rate limiting
        local total_stats = #all_stats
        
        log.info("Starting: Processing " .. tostring(total_stats) .. " stats one at a time...")
        notify.info("UnlockAll-Rewards", "Setting " .. tostring(total_stats) .. " stats...")
        
        -- Wait before starting
        log.info("Waiting " .. tostring(INITIAL_DELAY_MS) .. "ms before starting...")
        script.yield(INITIAL_DELAY_MS)
        
        -- Ensure no transactions are pending
        if is_transaction_pending() then
            log.info("Transactions pending at start, waiting...")
            notify.info("UnlockAll-Rewards", "Waiting for transactions to clear...")
            wait_for_transaction()
        end
        
        local processed = 0
        local failed_stats = {}
        local last_progress_notification = 0
        
        for i, stat in ipairs(all_stats) do
            -- Check for transactions before each stat
            if is_transaction_pending() then
                log.info("Waiting for pending transactions before stat " .. tostring(i) .. "/" .. tostring(total_stats) .. "...")
                wait_for_transaction()
            end
            
            -- Set stat with retry
            local success, error_msg, had_transaction = set_stat_with_retry(stat)
            
            -- Adjust delay based on transaction activity
            adjust_delay(had_transaction)
            
            if success then
                processed = processed + 1
            else
                table.insert(failed_stats, {
                    name = stat.name,
                    type = stat.type,
                    value = stat.value,
                    error = error_msg or "Unknown error"
                })
                log.warn("Failed to set stat " .. stat.name .. ": " .. tostring(error_msg))
            end
            
            -- Progress notifications
            local progress_pct = math.floor((i / total_stats) * 100)
            if progress_pct >= last_progress_notification + PROGRESS_NOTIFICATION_INTERVAL then
                last_progress_notification = progress_pct
                local remaining = total_stats - i
                local status_msg = tostring(progress_pct) .. "% (" .. tostring(i) .. "/" .. tostring(total_stats) .. ")"
                status_msg = status_msg .. "\nSet: " .. tostring(processed) .. " | Remaining: " .. tostring(remaining)
                if #failed_stats > 0 then
                    status_msg = status_msg .. " | Failed: " .. tostring(#failed_stats)
                end
                notify.info("UnlockAll-Rewards Progress", status_msg)
            end
        end
        
        -- Final wait for all transactions to complete
        if is_transaction_pending() then
            log.info("Waiting for final transactions to complete...")
            wait_for_transaction()
        end
        
        -- ===== Final Summary =====
        local success_count = processed
        local failed_count = #failed_stats
        
        log.info("==========================================================")
        log.info("================== Processing Complete ===================")
        log.info("Total Stats: " .. tostring(total_stats))
        log.info("Set: " .. tostring(success_count))
        log.info("Failed: " .. tostring(failed_count))
        log.info("Final adaptive delay: " .. tostring(CURRENT_DELAY_MS) .. "ms")
        log.info("==========================================================")
        
        -- Report failed stats if any
        if failed_count > 0 then
            log.warn("Failed stats (" .. tostring(failed_count) .. "):")
            for i, failed_stat in ipairs(failed_stats) do
                log.warn("  - " .. failed_stat.name .. " (" .. failed_stat.type .. " = " .. tostring(failed_stat.value) .. "): " .. tostring(failed_stat.error))
            end
            local summary_msg = "Total: " .. tostring(total_stats)
            summary_msg = summary_msg .. "\nSet: " .. tostring(success_count) .. " | Failed: " .. tostring(failed_count)
            notify.warn("UnlockAll-Rewards Complete", summary_msg)
        else
            local summary_msg = "Total: " .. tostring(total_stats)
            summary_msg = summary_msg .. "\nSet: " .. tostring(success_count) .. " stats"
            summary_msg = summary_msg .. "\nPlease check your awards page."
            notify.success("UnlockAll-Rewards Complete", summary_msg)
        end
        
        script.yield(2000)
    else
        notify.info("Script - All Awards Only", "Please join any freemode session and reload the script.")
    end
end)