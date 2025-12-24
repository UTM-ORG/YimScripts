script.run_in_callback(function()
log.info("\n\27[4;33mScript\27[m - \27[4;37mCasino Heist Reset\27[m\nInitialized successfully.")
    natives.load_natives()
    local IsOnline = NETWORK.NETWORK_IS_SESSION_STARTED() and not NETWORK.NETWORK_IS_IN_TRANSITION() and not STREAMING.IS_PLAYER_SWITCH_IN_PROGRESS()
    
    if IsOnline then
        stats.set_int("MPX_H3OPT_POI", 0)
        stats.set_int("MPX_H3OPT_ACCESSPOINTS", 0)
        notify.info("Success!","Diamond Casino Heist POI's and Access Points have been reset.")
    else
        notify.info("Script - Casino Heist Reset", "Please join any freemode session and reload the script.")
    end
end)