script.run_in_callback(function()
log.info("\n\27[4;33mScript\27[m - \27[4;37mAll Collectibles Only\27[m\nInitialized successfully.") -- By ImagineNothing
    local IsOnline = ScriptGlobal(2655288):get_int() ~= -1
    -- IsOnline = true
    
    if IsOnline then
        stats.set_packed_range(26811, 26910, true) -- Action Figures
        stats.set_packed_range(26911, 26964, true) -- LD Organics Product
        stats.set_packed_range(28099, 28148, true) -- Movie Props
        stats.set_packed_range(30230, 30239, true) -- Playing Cards
        stats.set_packed_range(34262, 34361, true) -- Signal Jammers
        stats.set_packed_range(36630, 36654, true) -- Snowmen
        stats.set_packed_range(51302 , 51337, true) -- Yuanbao
        stats.set_packed_range(54737 , 54761, true) -- Lucky Clovers
        notify.info("Success!","All collectibles have been unlocked")
    else
        notify.info("Script - All Collectibles Only", "Please join any freemode session and reload the script.")
    end
end)