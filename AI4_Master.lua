-- Planet Color
Planet_Red      = 236
Planet_Green    = 208
Planet_Blue     = 120

distance = 20
gridSize = 3 -- The Grid Size. 3 is for a 3x3 grid, set the number of agents to 9 (3x3).
lineNr = 1


-- Init of the lua Test_Master, function called upon initilization of the LUA auton:
function initAuton(x, y, id, macroFactor, timeResolution)

    height, width = l_getEnvironmentSize()

    if id == 1 then
        generatePlanet(height, width)
        l_addSharedNumber("lineKey",lineNr)
        --dofile([[C:/Master/RANA/lua_agents/AI4_Automaton.lua]])
        --initAgent(10, 10, id, macroFactor, timeResolution)
    end

    lineNr = l_getSharedNumber("lineKey")

    list = {id-1, id+1, id-gridSize, id+gridSize}

    dofile([[C:/Master/GitHub/LUA_Agents/AI4_Automaton.lua]])
    initAgent(10+((id-1)%gridSize)*distance, 10+(distance*(lineNr-1)), id, macroFactor, timeResolution, list)

    if (id % gridSize) == 0 then
        lineNr = l_getSharedNumber("lineKey")
        l_addSharedNumber("lineKey",(lineNr+1))
    end
end

function generatePlanet(_height, _width)
    for i = 0, height, 1 do
        for j = 0, width, 1 do
            l_modifyMap(i,j,Planet_Red,Planet_Green,Planet_Blue)
        end
    end
end
