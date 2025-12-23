script.run_in_callback(function()
log.verbose("\n\27[4;33mScript\27[m - \27[4;37mDr. Dre Contract Skip\27[m\nInitialized successfully.") -- By ImagineNothing
	local IsOnline = ScriptGlobal(2655288):get_int() ~= -1
	-- IsOnline = true
	
	if IsOnline then
		stats.set_int("MPX_FIXER_STORY_BS", 4095)
		notify.info("Script - Dr. Dre Contract Skip", "Success! All preps skipped.\nNext mission: Don't F* With Dre")
	else
		notify.info("Script - Dr. Dre Contract Skip", "Please join any freemode session and reload the script.")
	end
end)