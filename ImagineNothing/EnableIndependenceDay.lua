start = gui.get_tab("Enable Independence Day")
    
INDE = -648209009 -- or "TOGGLE_ACTIVATE_INDEPENDENCE_PACK"
    
IN = start:add_checkbox("Enable")
script.register_looped("INDE", function(script)
    script:yield()
    if IN:is_enabled() then
        tunables.set_int(INDE, 1)
    else
        tunables.set_int(INDE, 0)
    end
end)