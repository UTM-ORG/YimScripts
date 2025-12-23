script.run_in_callback(function()
log.info("\n\27[37m\27[4;33mScript\27[m - \27[4;37mRagdoll\27[m\nInitialized successfully.") -- By ImagineNothing
    local IsOnline = ScriptGlobal(2655288):get_int() ~= -1
    -- IsOnline = true
    natives.load_natives()
    
    if IsOnline then
        script.run_in_callback(function()
            while true do
                if PAD.IS_CONTROL_PRESSED(0, 29) then
                    PED.SET_PED_TO_RAGDOLL(PLAYER.PLAYER_PED_ID(), 2000, 2000, 0, 0, 0, 0)
                end
                script.yield()
            end
        end)
    else
        notify.info("Script - Ragdoll", "Please join any freemode session and reload the script.")
    end
end)