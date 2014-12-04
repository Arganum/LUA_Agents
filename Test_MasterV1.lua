

-- Init of the lua Test_Master, function called upon initilization of the LUA auton:
function initAuton(x, y, id, macroFactor, timeResolution)	

    if id == 1 then
        dofile([[C:/Master/RANA/lua_agents/Test_CarV2.lua]])
        initAgent(10, 50, id, macroFactor, timeResolution, 20)
    elseif id == 2 then
        dofile([[C:/Master/RANA/lua_agents/Test_CarV2.lua]])
        initAgent(20, 50, id, macroFactor, timeResolution, 40)
    end
end
