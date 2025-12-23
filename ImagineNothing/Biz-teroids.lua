---------------------------------BIZ-TEROIDS CONTROL PANEL---------------------------------
    
local HGWHrestock = true	-- Should the script restock your Hangar and Warehouse(s)? - true as default
local HGWHmaxgoods = true 	-- Should the script instantly max out your Hangar and Warehouse(s) stock? - false will restock with mixed goods but it's a bit slower - The four lines below depends on this one - true as default
local HGsetgood = false 	-- Goods type for Hangar will be random if this is set to false. - false as default
    local HGgoodtype = 6 	-- 0 = Animal Materials | 1 = Art & Antiques | 2 = Chemicals | 3 = Counterfeit Goods | 4 = Jewelry & Gemstones | 5 = Medical Supplies | 6 = Narcotics  | 7 = Tobacco & Alcohol
local WHsetgood = false 	-- Goods type for Warehouse(s) will be random if this is set to false. - false as default
    local WHgoodtype = 6 	-- 0 = Medical Supplies | 1 = Tobacco & Alcohol | 2 = Art & Antiques | 3 = Electronic Goods | 4 = Weapons & Ammo | 5 = Narcotics | 6 = Gemstones | 7 = Animal Materials | 8 = Counterfeit Goods | 9 = Jewelry | 10 = Bullion
local MCresup = true 		-- Should the script resupply all your MC Businesses? - true as default (idk why would you disable this)
local MCrestock = true 		-- Should the script restock your MC Businesses? - true as default
local NCgoods = true 		-- Should the script restock your Nightclub? - true as default
    
---------------------------------BIZ-TEROIDS CONTROL PANEL---------------------------------
    
script.run_in_callback(function()
log.verbose("\n\27[4;33mScript\27[m - \27[4;37mBiz-teroids\27[m\nInitialized successfully.\nNo, I'm not changing the name.\n")
    log.warn([[
    
        
            __     This script will start with hangar and warehouses restock,
    \ ______/ V`-,  then it'll resupply and restock available mc businesses,
    }        /~~  nightclub restock (not perfect) and popularity bar refill comes next
    /_)^ --,r'    and lastly it will refill salvage yard reputation and remove the heat
    |b      |b   from all three money fronts businesses.
    Added pauses here and there so notifications don't show up all at once.
    Main logic will start in 10s.								 
    ]])
local whprop, hangarprop, bbizprop, ncprop, syprop, cwprop = 1845299 + 1 + 260 + 128, 1845299 + 1 + 260 + 304, 1845299 + 1 + 260 + 205, 1845299 + 1 + 260 + 364, 1845299 + 1 + 260 + 504, 1882717 + 1 + 158 + 27
    
    if ScriptGlobal(2655288):get_int() ~= -1 then
        notify.info("Script - Biz-teroids by ImagineNothing", "Main logic will start in 10s.")
        script.yield(10000)
        
        if HGWHrestock then	
            if HGWHmaxgoods then
                notify.info("Script - Biz-teroids", "Hangar and Warehouse(s) instant max restock enabled.")
            else
                notify.info("Script - Biz-teroids", "Hangar and Warehouse(s) instant max restock disabled. Businesses will be replenished with mixed goods.")
            end
            script.yield(1000)
            
            if ScriptGlobal(hangarprop):get_int() >= 1 then
                if ScriptGlobal(hangarprop + 3):get_int() <= 49 then
                    if HGWHmaxgoods then
                        if HGsetgood then
                            ScriptGlobal(1882707 + 8):set_int(HGgoodtype)
                        end
                        ScriptGlobal(1882707 + 7):set_int(50)
                        stats.set_packed_bool(36828, true)
                    else
                        for HGl = 0, 49 do
                            stats.set_packed_bool(36828, true)
                            script.yield(1500)
                        end
                    end
                    notify.success("Success!", "Hangar goods replenished!")
                else
                    notify.warn("Oops!", "Hangar is at max capacity.")
                end
            else
                notify.error("Script - Biz-teroids", "You don't own a Hangar")
            end
            
            if ScriptGlobal(whprop + 1):get_int() >= 1 then
                for c = 0, 4 do
                    if ScriptGlobal(whprop + 1):at(c, 3):get_int() <= 110 then
                        notify.success("Success!", "Warehouse(s) goods replenished!")
                        if HGWHmaxgoods then
                            if HGsetgood then
                                ScriptGlobal(1882682 + 16):set_int(WHgoodtype)
                            end
                            for i = 1, 5 do
                                for wh = 32359, 32363 do
                                    script.yield(100)
                                    ScriptGlobal(1882682 + 13):set_int(111)
                                    stats.set_packed_bool(wh, true)
                                end
                            end
                        else
                            for WHl = 0, 110 do
                                for i = 1, 5 do
                                    for wh = 32359, 32363 do
                                        script.yield(100)
                                        stats.set_packed_bool(wh, true)
                                    end
                                end
                            end
                        end
                    end
                end
                notify.warn("Oops!", "Warehouse(s) are at max capacity.")
            else
                notify.error("Script - Biz-teroids", "You don't own a Warehouse")
            end
        else
            notify.info("Script - Biz-teroids", "Hangar & Warehouse restocking disabled. Skipping...")
        end
    
local function GetBusinessSlot(businessName)
    
    local MCbizlocs = {
        [1] = "Paleto Bay", [6] = "El Burro Heights", [11] = "Gran Senora Desert", [16] = "Terminal",
        [2] = "Mount Chiliad", [7] = "Downtown Vinewood", [12] = "San Chianski Mountain Range", [17] = "Elysian Island",
        [3] = "Paleto Bay", [8] = "Morningwood", [13] = "Alamo Sea", [18] = "Elysian Island",
        [4] = "Paleto Bay", [9] = "Vespucci Canals", [14] = "Gran Senora Desert", [19] = "Cypress Flats",
        [5] = "Paleto Bay", [10] = "Textile City", [15] = "Grapeseed", [20] = "Elysian Island",
        [21] = "Grand Senora Oilfields", [22] = "Grand Senora Desert", [23] = "Route 68", [24] = "Farmhouse", [25] = "Smoke Tree Road", [26] = "Thomson Scrapyard", [27] = "Grapeseed", [28] = "Paleto Forest", [29] = "Raton Canyon", [30] = "Lago Zancudo", [31] = "Chumash"
    }
    local MCbiz = {
        { MCBname = "Methamphetamine Lab", ID = { 1, 6, 11, 16 } },
        { MCBname = "Weed Farm", ID = { 2, 7, 12, 17 } },
        { MCBname = "Cocaine Lockup", ID = { 3, 8, 13, 18 } },
        { MCBname = "Counterfeit Cash Factory", ID = { 4, 9, 14, 19 } },
        { MCBname = "Document Forgery Office", ID = { 5, 10, 15, 20 } },
        { MCBname = "Bunker", ID = { 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31 } }
    }
    for _, business in ipairs(MCbiz) do -- Credit to Silenthy6 (SilentSalo) for this part [url]https://www.unknowncheats.me/forum/4380348-post701.html[/url] (it was too much for my brain)
        if business.MCBname == businessName then
            for i = 0, 5 do
                local slot = ScriptGlobal(bbizprop):at(i, 13):get_int()
                if slot > 0 then
                    for _, id in ipairs(business.ID) do
                        if slot == id then
                            local mcbizloc = MCbizlocs[slot]
                            log.info("\r\27[1;36mBusiness:\27[1;92m "..businessName.." \27[m| \27[1;36mLocation:\27[m "..mcbizloc.." | \27[1;36mSlot:\27[m "..i.." | \27[1;36mID:\27[m "..slot.."            \r")
                            return true, i
                        end
                    end
                end
            end
        end
    end
end
    
        script.yield(3000)
        
        if MCresup then
            for b = 0, 7 do
                if ScriptGlobal(bbizprop):at(b, 13):get_int() >= 1 then
                    for bsup = 1, 7 do
                        ScriptGlobal(1673814 + bsup):set_int(1)
                        notify.success("Success!", "All businesses supplies have been replenished!")
                    end
                end
            end
        end
        
        script.yield(3000)
    
        script.run_in_callback(function()
            natives.load_natives()
            while true do
                if ScriptGlobal(2652582 + 2706):get_int() ~= -1 then
                    if PAD.IS_CONTROL_PRESSED(0, 171) or PAD.IS_CONTROL_PRESSED(0, 194) then
                        SCRIPT.REQUEST_SCRIPT("apparcadebusinesshub")
                        if SCRIPT.HAS_SCRIPT_LOADED("apparcadebusinesshub") then
                            BUILTIN.START_NEW_SCRIPT("apparcadebusinesshub", 8344)
                            SCRIPT.SET_SCRIPT_AS_NO_LONGER_NEEDED("appsecuroserv")
                        end
                    end
                end
                script.yield(200)
            end
        end)
        notify.info("Script - Biz-teroids", "Master Control Terminal ready.\nPress BACKSPACE or CAPSLOCK to manage your businesses.")
        
        if MCrestock then
            notify.info("Script - Biz-teroids", "MC Businesses restock enabled.")
            
            local methmc, slot = GetBusinessSlot("Methamphetamine Lab")
            if methmc then
                if ScriptGlobal(bbizprop + 1):at(slot, 13):get_int() <= 19 then
                    for _, manuprod in ipairs({1370024930, 1944848251, 1577999189, 1678460062}) do
                        tunables.set_int(manuprod, 1)
                    end
                    for _, manucost in ipairs({-730135062, -660914094}) do
                        tunables.set_int(manucost, 1)
                    end
                    script.yield(2000)
                    notify.success("Success!", "Meth Business restock ready!\nPlease restart your business.")
                else
                    notify.warn("Oops!", "Meth Business stock is at max capacity!")
                end
            else
                notify.error("Script - Biz-teroids", "You don't own a Methamphetamine Lab.")
            end
            
            local weedmc, slot = GetBusinessSlot("Weed Farm")
            if weedmc then
                if ScriptGlobal(bbizprop + 1):at(slot, 13):get_int() <= 79 then
                    for _, manuprod in ipairs({-635596193, -1694873660, 1575359233, 102029883}) do
                        tunables.set_int(manuprod, 1)
                    end
                    for _, manucost in ipairs({-373027461, 1195564032}) do
                        tunables.set_int(manucost, 1)
                    end
                    script.yield(2000)
                    notify.success("Success!", "Weed Business restock ready!\nPlease restart your business.")
                else
                    notify.warn("Oops!", "Weed Business stock is at max capacity!")
                end
            else
                notify.error("Script - Biz-teroids", "You don't own a Weed Farm.")
            end
            
            local crackmc, slot = GetBusinessSlot("Cocaine Lockup")
            if crackmc then
                if ScriptGlobal(bbizprop + 1):at(1, 13):get_int() <= 9 then
                    for _, manuprod in ipairs({702413484, 2070857577, -1539796661, 396217128}) do
                        tunables.set_int(manuprod, 1)
                    end
                    for _, manucost in ipairs({-161187879, 1500658261}) do
                        tunables.set_int(manucost, 1)
                    end
                    script.yield(2000)
                    notify.success("Success!", "Coke Business restock ready!\nPlease restart your business.")
                else
                    notify.warn("Oops!", "Coke Business stock is at max capacity!")
                end
            else
                notify.error("Script - Biz-teroids", "You don't own a Cocaine Lockup.")
            end
            
            local cashmc, slot = GetBusinessSlot("Counterfeit Cash Factory")
            if cashmc then
                if ScriptGlobal(bbizprop + 1):at(0, 13):get_int() <= 39 then
                    for _, manuprod in ipairs({1310272402, 1690071006, -1454958662, -1913260493}) do
                        tunables.set_int(manuprod, 1)
                    end
                    for _, manucost in ipairs({631857857, -891680742}) do
                        tunables.set_int(manucost, 1)
                    end
                    script.yield(2000)
                    notify.success("Success!", "Cash Business restock ready!\nPlease restart your business.")
                else
                    notify.warn("Oops!", "Cash Business stock is at max capacity!")
                end
            else
                notify.error("Script - Biz-teroids", "You don't own a Counterfeit Cash Factory.")
            end
            
            local fakeidmc, slot = GetBusinessSlot("Document Forgery Office")
            if fakeidmc then
                if ScriptGlobal(bbizprop + 1):at(slot, 13):get_int() <= 59 then
                    for _, manuprod in ipairs({-959721585, 1672482518, -518264160, 489023341}) do
                        tunables.set_int(manuprod, 1)
                    end
                    for _, manucost in ipairs({-1839004359, -192060672}) do
                        tunables.set_int(manucost, 1)
                    end
                    script.yield(2000)
                    notify.success("Success!", "Documents Business restock ready!\nPlease restart your business.")
                else
                    notify.warn("Oops!", "Documents Business stock is at max capacity!")
                end
            else
                notify.error("Script - Biz-teroids", "You don't own a Document Forgery Office.")
            end
            
            local bunkermc, slot = GetBusinessSlot("Bunker")
            if bunkermc then
                if ScriptGlobal(bbizprop + 1):at(slot, 13):get_int() <= 99 then
                    for _, manuprod in ipairs({215868155, 631477612, 818645907}) do
                        tunables.set_int(manuprod, 1)
                    end
                    for _, manucost in ipairs({-1652502760, 1647327744}) do
                        tunables.set_int(manucost, 1)
                    end
                    script.yield(2000)
                    notify.success("Success!", "Bunker Business restock ready!\nPlease restart your business.")
                end
            else
                notify.error("Script - Biz-teroids", "You don't own a Bunker.")
            end
            
            if ScriptGlobal(bbizprop):at(6, 13):get_int() >= 1 then
                if ScriptGlobal(bbizprop + 1):at(6, 13):get_int() <= 159 then
                    for _, manuprod in ipairs({-672998848, 494316332, -40235252}) do
                        tunables.set_int(manuprod, 1)
                    end
                    for _, manucost in ipairs({-1506354854, -993236072}) do
                        tunables.set_int(manucost, 1)
                    end
                    script.yield(2000)
                    notify.success("Success!", "Acid Lab Business restock ready!\nPlease restart your business.")
                end
            else
                notify.error("Script - Biz-teroids", "You don't own an Acid Lab.")
            end
        else
            notify.info("Script - Biz-teroids", "MC Businesses restocking disabled. Skipping...")
        end
        
        script.yield(3000)
        
        if ScriptGlobal(ncprop):get_int() >= 1 then
            if ScriptGlobal(ncprop + 4):get_float() <= 99.0 then
                stats.set_int("MPX_CLUB_POPULARITY", 1000)
                notify.success("Success!", "Nightclub Popularity has been maxed out!")
            end
            if NCgoods then
                for _, manuprod in ipairs({-147565853, -1390027611, -1292210552, 1007184806, 18969287, -863328938, 1607981264}) do
                    tunables.set_int(manuprod, 1)
                end
                notify.success("Success!", "Nightclub restock ready!\nPlease re-assign your technicians.")
            end
            script.yield(2000)
        else
            notify.error("Script - Biz-teroids", "You don't own a Nightclub.")
        end
        
        if ScriptGlobal(syprop):get_int() >= 1 then
            stats.set_packed_int(51051, 100)
            notify.success("Success!", "Salvage Yard Popularity has been maxed out!")
            script.yield(2000)
        else
            notify.error("Script - Biz-teroids", "You don't own a Salvage Yard.")
        end
    
        if ScriptGlobal(cwprop + 1):get_int() >= 1 and ScriptGlobal(cwprop + 13):get_int() >= 0 then
            for tycoonh = 24924, 24926 do
                stats.set_packed_int(tycoonh, 0)
            end
            notify.success("Success!", "Money Fronts Businesses Heat Removed!")
            script.yield(2000)
        else
            notify.error("Script - Biz-teroids", "You don't own Hands on Car Wash.")
        end
    else
        notify.info("Script - Biz-teroids", "Please join any freemode session and reload the script.")
    end
end)