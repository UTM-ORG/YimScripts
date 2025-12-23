---------------------------------Gun Van Halen - Slots Editor---------------------------------
-- Here you can edit the gun van weapons slots by entering the weapon ID or NAME (Don't forget the quotation marks), which can be found just below this part. --
    
local GunVan_Slot_1  = 	"Railgun"
local GunVan_Slot_2  = 	"Tactical SMG"
local GunVan_Slot_3  = 	"El Strickler"
local GunVan_Slot_4  = 	"Knife"
local GunVan_Slot_5  = 	67 -- Up-n-Atomizer 
local GunVan_Slot_6  = 	84 -- Railgun
local GunVan_Slot_7  = 	"Baseball Bat"
local GunVan_Slot_8  = 	86 -- Snowball Launcher
local GunVan_Slot_9  = 	"Unholy Hellbringer"
local GunVan_Slot_10 = 	82 -- Candy Cane
    
local GunVan_Slot_Throwable_1 = 20 -- Grenade
local GunVan_Slot_Throwable_2 = "Tear Gas"
local GunVan_Slot_Throwable_3 = 22 -- Sticky Bomb
    
local expandradar = true -- Should the script expand your minimap?
    
---------------------------------Gun Van Halen - Slots Editor---------------------------------
    
local GVweapons = {
    { id = 1,   name = "Pistol",                    hash = "WEAPON_PISTOL"},
    { id = 2,   name = "Combat Pistol",             hash = "WEAPON_COMBATPISTOL"},
    { id = 3,   name = "AP Pistol",                 hash = "WEAPON_APPISTOL"},
    { id = 4,   name = "Pistol .50",                hash = "WEAPON_PISTOL50"},
    { id = 5,   name = "SMG",                       hash = "WEAPON_SMG"},
    { id = 6,   name = "Micro SMG",                 hash = "WEAPON_MICROSMG"},
    { id = 7,   name = "Assault Rifle",             hash = "WEAPON_ASSAULTRIFLE"},
    { id = 8,   name = "Carbine Rifle",             hash = "WEAPON_CARBINERIFLE"},
    { id = 9,   name = "Advanced Rifle",            hash = "WEAPON_ADVANCEDRIFLE"},
    { id = 10,  name = "MG",                        hash = "WEAPON_MG"},
    { id = 11,  name = "Combat MG",                 hash = "WEAPON_COMBATMG"},
    { id = 12,  name = "Pump Shotgun",              hash = "WEAPON_PUMPSHOTGUN"},
    { id = 13,  name = "Sawed-Off Shotgun",         hash = "WEAPON_SAWNOFFSHOTGUN"},
    { id = 14,  name = "Assault Shotgun",           hash = "WEAPON_ASSAULTSHOTGUN"},
    { id = 15,  name = "Heavy Sniper",              hash = "WEAPON_HEAVYSNIPER"},
    { id = 16,  name = "Sniper Rifle",              hash = "WEAPON_SNIPERRIFLE"},
    { id = 17,  name = "Grenade Launcher",          hash = "WEAPON_GRENADELAUNCHER"},
    { id = 18,  name = "RPG",                       hash = "WEAPON_RPG"},
    { id = 19,  name = "Minigun",                   hash = "WEAPON_MINIGUN"},
    { id = 20,  name = "Grenade",                   hash = "WEAPON_GRENADE"},
    { id = 21,  name = "Tear Gas",                  hash = "WEAPON_SMOKEGRENADE"},
    { id = 22,  name = "Sticky Bomb",               hash = "WEAPON_STICKYBOMB"},
    { id = 23,  name = "Molotov",                   hash = "WEAPON_MOLOTOV"},
    { id = 24,  name = "Jerry Can",                 hash = "WEAPON_PETROLCAN"},
    { id = 25,  name = "Knife",                     hash = "WEAPON_KNIFE"},
    { id = 26,  name = "Nightstick",                hash = "WEAPON_NIGHTSTICK"},
    { id = 27,  name = "Hammer",                    hash = "WEAPON_HAMMER"},
    { id = 28,  name = "Baseball Bat",              hash = "WEAPON_BAT"},
    { id = 29,  name = "Crowbar",                   hash = "WEAPON_CROWBAR"},
    { id = 30,  name = "Golf Club",                 hash = "WEAPON_GOLFCLUB"},
    { id = 31,  name = "Assault SMG",               hash = "WEAPON_ASSAULTSMG"},
    { id = 32,  name = "Bullpup Shotgun",           hash = "WEAPON_BULLPUPSHOTGUN"},
    { id = 33,  name = "Bottle",                    hash = "WEAPON_BOTTLE"},
    { id = 34,  name = "Special Carbine",           hash = "WEAPON_SPECIALCARBINE"},
    { id = 35,  name = "SNS Pistol",                hash = "WEAPON_SNSPISTOL"},
    { id = 36,  name = "Heavy Pistol",              hash = "WEAPON_HEAVYPISTOL"},
    { id = 37,  name = "Bullpup Rifle",             hash = "WEAPON_BULLPUPRIFLE"},
    { id = 38,  name = "Gusenberg Sweeper",         hash = "WEAPON_GUSENBERG"},
    { id = 39,  name = "Vintage Pistol",            hash = "WEAPON_VINTAGEPISTOL"},
    { id = 40,  name = "Antique Cavalry Dagger",    hash = "WEAPON_DAGGER"},
    { id = 41,  name = "Musket",                    hash = "WEAPON_MUSKET"},
    { id = 42,  name = "Firework Launcher",         hash = "WEAPON_FIREWORK"},
    { id = 43,  name = "Flare Gun",                 hash = "WEAPON_FLAREGUN"},
    { id = 44,  name = "Heavy Shotgun",             hash = "WEAPON_HEAVYSHOTGUN"},
    { id = 45,  name = "Marksman Rifle",            hash = "WEAPON_MARKSMANRIFLE"},
    { id = 46,  name = "Proximity Mine",            hash = "WEAPON_PROXMINE"},
    { id = 47,  name = "Homing Launcher",           hash = "WEAPON_HOMINGLAUNCHER"},
    { id = 48,  name = "Hatchet",                   hash = "WEAPON_HATCHET"},
    { id = 49,  name = "Combat PDW",                hash = "WEAPON_COMBATPDW"},
    { id = 50,  name = "Knuckle Duster",            hash = "WEAPON_KNUCKLE"},
    { id = 51,  name = "Marksman Pistol",           hash = "WEAPON_MARKSMANPISTOL"},
    { id = 52,  name = "Machete",                   hash = "WEAPON_MACHETE"},
    { id = 53,  name = "Machine Pistol",            hash = "WEAPON_MACHINEPISTOL"},
    { id = 54,  name = "Double Barrel Shotgun",     hash = "WEAPON_DBSHOTGUN"},
    { id = 55,  name = "Compact Rifle",             hash = "WEAPON_COMPACTRIFLE"},
    { id = 56,  name = "Flashlight",                hash = "WEAPON_FLASHLIGHT"},
    { id = 57,  name = "Heavy Revolver",            hash = "WEAPON_REVOLVER"},
    { id = 58,  name = "Switchblade",               hash = "WEAPON_SWITCHBLADE"},
    { id = 59,  name = "Sweeper Shotgun",           hash = "WEAPON_AUTOSHOTGUN"},
    { id = 60,  name = "Mini SMG",                  hash = "WEAPON_MINISMG"},
    { id = 61,  name = "Compact Grenade Launcher",  hash = "WEAPON_COMPACTLAUNCHER"},
    { id = 62,  name = "Battle Axe",                hash = "WEAPON_BATTLEAXE"},
    { id = 63,  name = "Pipe Bomb",                 hash = "WEAPON_PIPEBOMB"},
    { id = 64,  name = "Pool Cue",                  hash = "WEAPON_POOLCUE"},
    { id = 65,  name = "Pipe Wrench",               hash = "WEAPON_WRENCH"},
    { id = 66,  name = "Double-Action Revolver",    hash = "WEAPON_DOUBLEACTION"},
    { id = 67,  name = "Up-n-Atomizer",             hash = "WEAPON_RAYPISTOL"},
    { id = 68,  name = "Unholy Hellbringer",        hash = "WEAPON_RAYCARBINE"},
    { id = 69,  name = "Widowmaker",                hash = "WEAPON_RAYMINIGUN"},
    { id = 70,  name = "Stone Hatchet",             hash = "WEAPON_STONE_HATCHET"},
    { id = 71,  name = "Navy Revolver",             hash = "WEAPON_NAVYREVOLVER"},
    { id = 72,  name = "Ceramic Pistol",            hash = "WEAPON_CERAMICPISTOL"},
    { id = 73,  name = "Perico Pistol",             hash = "WEAPON_GADGETPISTOL"},
    { id = 74,  name = "Military Rifle",            hash = "WEAPON_MILITARYRIFLE"},
    { id = 75,  name = "Combat Shotgun",            hash = "WEAPON_COMBATSHOTGUN"},
    { id = 76,  name = "Heavy Rifle",               hash = "WEAPON_HEAVYRIFLE"},
    { id = 77,  name = "Compact EMP Launcher",      hash = "WEAPON_EMPLAUNCHER"},
    { id = 78,  name = "Stun Gun",                  hash = "WEAPON_STUNGUN_MP"},
    { id = 79,  name = "Service Carbine",           hash = "WEAPON_TACTICALRIFLE"},
    { id = 80,  name = "Precision Rifle",           hash = "WEAPON_PRECISIONRIFLE"},
    { id = 81,  name = "WM 29 Pistol",              hash = "WEAPON_PISTOLXM3"},
    { id = 82,  name = "Candy Cane",                hash = "WEAPON_CANDYCANE"},
    { id = 83,  name = "Railgun",                   hash = "WEAPON_RAILGUNXM3"},
    { id = 84,  name = "Tactical SMG",              hash = "WEAPON_TECPISTOL"},
    { id = 85,  name = "Battle Rifle",              hash = "WEAPON_BATTLERIFLE"},
    { id = 86,  name = "Snowball Launcher",         hash = "WEAPON_SNOWLAUNCHER"},
    { id = 87,  name = "The Shocker",               hash = "WEAPON_STUNROD"},
    { id = 88,  name = "El Strickler",              hash = "WEAPON_STRICKLER"}
}
    
    
local gunvanlocs = {
    [1] = {locname = "Paleto Bay",         		GVcoords = {-29.532, 6435.136, 31.162}},
    [2] = {locname = "Grapeseed",          		GVcoords = {1705.214, 4819.167, 41.75}},
    [3] = {locname = "Sandy Shores",       		GVcoords = {1795.522, 3899.753, 33.869}},
    [4] = {locname = "Grand Senora Desert",		GVcoords = {1335.536, 2758.746, 51.099}},
    [5] = {locname = "Vinewood Sign",     		GVcoords = {795.583, 1210.78, 338.962}}, -- *Galileo Park - Vinewood Hills
    [6] = {locname = "Chumash",            		GVcoords = {-3192.67, 1077.205, 20.594}},
    [7] = {locname = "Paleto Forest",      		GVcoords = {-789.719, 5400.921, 33.915}},
    [8] = {locname = "Zancudo River",      		GVcoords = {-24.384, 3048.167, 40.703}},
    [9] = {locname = "Power Station",      		GVcoords = {2666.786, 1469.324, 24.237}}, -- *Palmer-Taylor Power Station
    [10] = {locname = "Lago Zancudo",      		GVcoords = {-1454.966, 2667.503, 3.2}}, -- *Fort Zancudo Approach Rd
    [11] = {locname = "Thomson Scrapyard", 		GVcoords = {2340.418, 3054.188, 47.888}},
    [12] = {locname = "El Burro Heights",  		GVcoords = {1509.183, -2146.795, 76.853}}, -- *Car Scrapyard
    [13] = {locname = "Murrieta Heights",  		GVcoords = {1137.404, -1358.654, 34.322}},
    [14] = {locname = "Elysian Island",    		GVcoords = {-57.208, -2658.793, 5.737}},
    [15] = {locname = "Tataviam Mountains",		GVcoords = {1905.017, 565.222, 175.558}}, -- *Land Act Reservoir
    [16] = {locname = "La Mesa",           		GVcoords = {974.484, -1718.798, 30.296}}, -- *Fridgit, Forced Labor Place
    [17] = {locname = "Terminal",          		GVcoords = {779.077, -3266.297, 5.719}},
    [18] = {locname = "La Puerta",         		GVcoords = {-587.728, -1637.208, 19.611}}, -- *Rogers Salvage & Scrap
    [19] = {locname = "La Mesa",           		GVcoords = {733.99, -736.803, 26.165}}, -- *Popular Street
    [20] = {locname = "Del Perro",         		GVcoords = {-1694.632, -454.082, 40.712}},
    [21] = {locname = "Magellan Ave",      		GVcoords = {-1330.726, -1163.948, 4.313}}, -- *Vespucci Beach
    [22] = {locname = "West Vinewood",     		GVcoords = {-496.618, 40.231, 52.316}},
    [23] = {locname = "Downtown Vinewood", 		GVcoords = {275.527, 66.509, 94.108}},
    [24] = {locname = "Pillbox Hill",      		GVcoords = {260.928, -763.35, 30.559}},
    [25] = {locname = "Little Seoul",      		GVcoords = {-478.025, -741.45, 30.299}}, -- *Caesars Auto Parking
    [26] = {locname = "Alamo Sea",         		GVcoords = {894.94, 3603.911, 32.56}}, -- *Joshua Road
    [27] = {locname = "North Chumash",     		GVcoords = {-2166.511, 4289.503, 48.733}}, -- *Hookies
    [28] = {locname = "Mount Chiliad",     		GVcoords = {1465.633, 6553.67, 13.771}}, -- *Procopio Beach
    [29] = {locname = "Mirror Park",       		GVcoords = {1101.032, -335.172, 66.944}}, -- *Hearty Taco
    [30] = {locname = "Davis",             		GVcoords = {149.683, -1655.674, 29.028}} -- *Bishop's Chicken
}
    
script.run_in_callback(function()
    log.verbose("\n\27[4;33mScript\27[m - \27[4;37mGun Van Halen\27[m\nInitialized successfully.")
    if ScriptGlobal(2655288):get_int() ~= -1 then
    natives.load_natives()
    
        tunables.set_float(15999531, "inf") -- 2139095040
        script.yield(500)
        HUD.SET_BLIP_AS_SHORT_RANGE(HUD.GET_FIRST_BLIP_INFO_ID(844), false)
        notify.info("Script - Gun Van Halen", "Gun van icon is now visible from anywhere on the map!")
        if expandradar then
            stats.set_packed_bool(24, true)
            script.yield(500)
            stats.set_packed_bool(24, false)
            script.yield(500)
            stats.set_packed_bool(24, true)
            script.yield(500)
            stats.set_packed_bool(24, false)
        end
        script.yield(1500)
        
local function WeaponID(gvg)
    for _, gun in ipairs(GVweapons) do
        if gun.id == gvg or gun.name == gvg then
            return gun.hash, gun.name
        end
    end
end
    
local GVteleport = gunvanlocs[ScriptGlobal(2652582 + 2706):get_int() + 1]
        if GVteleport then
            log.info("\n--------------------------------------------\n\27[1;36mCurrent Gun Van Location:\27[m " .. GVteleport.locname .."\nTeleport \27[4;33mKey\27[m Ready\n--------------------------------------------")
            notify.info("Script - Gun Van Halen", "Current Gun Van Location: \n".. GVteleport.locname .."\nPress BACKSPACE or CAPSLOCK to teleport.")
        end
        
        script.run_in_callback(function()
        local coords = GVteleport.GVcoords
            while true do
                if tunables.get_float(15999531) ~= 500.0 then
                    if PAD.IS_CONTROL_PRESSED(0, 171) or PAD.IS_CONTROL_PRESSED(0, 194) then
                        PED.SET_PED_COORDS_KEEP_VEHICLE(PLAYER.PLAYER_PED_ID(), coords[1], coords[2], coords[3]+1.0)
                    end
                end
                script.yield(200)
            end
        end)
        
        script.yield(4000)
        local function SetWeapon(slot, weap)
            local hash, name = WeaponID(weap)
            log.info("\r\27[1;36mGun Van \27[0;95mWeapon Slot \27[4;95m" .. slot + 1 .. "\27[m set to:\27[0;33m " .. name.."\27[m                                    \r")
            tunables.set_int("XM22_GUN_VAN_SLOT_WEAPON_TYPE_" .. slot, util.joaat(hash))
        end
        
        local function SetThrowable(slot, throw)
            local hash, name = WeaponID(throw)
            log.info("\r\27[1;36mGun Van \27[0;95mThrowable Slot \27[4;95m" .. slot + 1 .. "\27[m set to:\27[0;33m " .. name.."\27[m                                    \r")
            tunables.set_int("XM22_GUN_VAN_SLOT_THROWABLE_TYPE_" .. slot, util.joaat(hash))
        end
        
        tunables.set_int(1490225691, 0)
        SetWeapon(0, GunVan_Slot_1)
        SetWeapon(1, GunVan_Slot_2)
        SetWeapon(2, GunVan_Slot_3)
        SetWeapon(3, GunVan_Slot_4)
        SetWeapon(4, GunVan_Slot_5)
        SetWeapon(5, GunVan_Slot_6)
        SetWeapon(6, GunVan_Slot_7)
        SetWeapon(7, GunVan_Slot_8)
        SetWeapon(8, GunVan_Slot_9)
        SetWeapon(9, GunVan_Slot_10)
        log.info("\r                                                       ")
        SetThrowable(0, GunVan_Slot_Throwable_1)
        SetThrowable(1, GunVan_Slot_Throwable_2)
        SetThrowable(2, GunVan_Slot_Throwable_3)
        log.info("\r                                                       ")
        notify.success("Script - Gun Van Halen", "Selected weapons are now available at the Gun Van.")
    else
        notify.info("Script - Gun Van Halen", "Please join any freemode session and reload the script.")
    end
end)