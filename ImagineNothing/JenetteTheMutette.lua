script.run_in_callback(function()
log.verbose("\n\27[4;33mScript\27[m - \27[4;37mJenette The Mutette\27[m\nInitialized successfully.") -- By ImagineNothing
    local IsOnline = ScriptGlobal(2655288):get_int() ~= -1
    -- IsOnline = true
    
    if IsOnline then
        stats.set_packed_bool_range(51192, 51195, true)
        notify.success("Script - Jenette The Mutette", "Success! Jenette dialogues have been skipped!")
    else
        notify.info("Script - Jenette The Mutette", "Please join any freemode session and reload the script.")
    end
end)