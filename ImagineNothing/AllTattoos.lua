script.run_in_callback(function()
log.verbose("\n\27[4;33mScript\27[m - \27[4;37mAll Tattoos Only\27[m\nInitialized successfully.") -- By ImagineNothing
    local IsOnline = ScriptGlobal(2655288):get_int() ~= -1
    -- IsOnline = true
    
    if IsOnline then
        for i = 0, 53 do
            stats.set_int("MPX_TATTOO_FM_UNLOCKS_"..i.."", -1)
        end
        for _, tatpb in ipairs({15737, 15738, 15887, 15898, 15894, 15905}) do -- ???, the royals, lucky 7s tattoos
            stats.set_packed_bool(tatpb, true)
            stats.set_packed_bool_range(41273, 41296, true) -- Monkey, Dragon, Snake, Goat, Rat, Rabbit, Ox, Pig, Rooster, Dog, Horse, Tiger
        end
        notify.info("Script - All Tattoos Only", "Success! All tattoos have been unlocked.")
    else
        notify.info("Script - All Tattoos Only", "Please join any freemode session and reload the script.")
    end
end)