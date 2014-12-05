-- Planet Color
Planet_Red      = 236
Planet_Green    = 208
Planet_Blue     = 120

distance = 20
grid = 3

-- Init of the lua Test_Master, function called upon initilization of the LUA auton:
function initAuton(x, y, id, macroFactor, timeResolution)

    height, width = l_getEnvironmentSize()

    if id == 1 then
        generatePlanet(height, width)
        --dofile([[C:/Master/RANA/lua_agents/AI4_Automaton.lua]])
        --initAgent(10, 10, id, macroFactor, timeResolution)
    end

    --if id

    list = {id-1, id+1, id-grid, id+grid}

    if id > 0 and id < grid+1 then
        for key, value in pairs(list) do
            if value < 0 or (((value%grid)-1 == 0) and key == 2 )  then
                list[key] = 0
            end
        end
        dofile([[C:/Master/GitHub/LUA_Agents/AI4_Automaton.lua]])
        initAgent(10+((id-1)%3)*distance, 10, id, macroFactor, timeResolution, list)
    end

    if id > 3 and id < 7 then
        for key, value in pairs(list) do
            if (((value%3) == 0) and key == 1 ) or (((value%3)-1 == 0) and key == 2 ) then
                list[key] = 0
            end
        end
        dofile([[C:/Master/GitHub/LUA_Agents/AI4_Automaton.lua]])
        initAgent(10+((id-1)%3)*distance, 10+distance, id, macroFactor, timeResolution, list)
    end

    if id > 6 and id < 10 then
        for key, value in pairs(list) do
            if value > 9 or (((value%3) == 0) and key == 1 ) or (((value%3)-1 == 0) and key == 2 ) then
                list[key] = 0
            end
        end
        dofile([[C:/Master/GitHub/LUA_Agents/AI4_Automaton.lua]])
        initAgent(10+((id-1)%3)*distance, 10+(distance*2), id, macroFactor, timeResolution, list)
    end

end

function generatePlanet(_height, _width)
    for i = 0, height, 1 do
        for j = 0, width, 1 do
            l_modifyMap(i,j,Planet_Red,Planet_Green,Planet_Blue)
        end
    end
end
