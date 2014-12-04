-- Global variables:
Ore_D           =  5 --%
Area_G          =  0
Ore             =  0

-- Explorer and Transporter Ratio per Base - eg. 8 agents in total: Robot_Total + One Base
Robot_Total     =   18 -- eg. 7
Explorer_Ratio  =    4 -- eg. 2 - Explorer_Ratio/Robot_Total eg. 2 Explorers and 5 Transporters per Base, 7 Robots in Total

-- Ore Color
Ore_Red         =  83
Ore_Green       = 119
Ore_Blue        = 122

-- Planet Color
Planet_Red      = 236
Planet_Green    = 208
Planet_Blue     = 120

-- Init of the lua Test_Master, function called upon initilization of the LUA auton:
function initAuton(x, y, id, macroFactor, timeResolution)	

    height, width = l_getEnvironmentSize()

    if id == 1 then
        generatePlanet(height, width)
    end

    if id % ( Robot_Total + 1 ) == 1 then
        dofile([[C:/Users/Lau/Desktop/MAS/RANA_QT-experimental/lua_agents/Test_Base.lua]])
        initAgent(x, y, id, macroFactor, timeResolution)
    elseif id % ( Robot_Total + 1 ) < ( Explorer_Ratio + 1 ) then
        dofile([[C:/Users/Lau/Desktop/MAS/RANA_QT-experimental/lua_agents/Test_Explorer.lua]])
        initAgent(x, y, id, macroFactor, timeResolution)
    else
        dofile([[C:/Users/Lau/Desktop/MAS/RANA_QT-experimental/lua_agents/Test_Transporter.lua]])
        initAgent(x, y, id, macroFactor, timeResolution)
    end


    if id == 1 then
        generateOre(height, width)
    end
end

function generatePlanet(height, width)
    for i = 0, height, 1 do
        for j = 0, width, 1 do
            l_modifyMap(i,j,Planet_Red,Planet_Green,Planet_Blue)
        end
    end
end

function generateOre(height, width)
    Area_G = ( height + 1 ) * ( width + 1 )
    --l_debug(Area_G)
    Ore = ( Area_G / 100 ) * Ore_D
    --l_debug(Ore)

    while ( Ore ~= 0 ) do
        Ore_PosX = l_getMersenneInteger(0,height-1)
        Ore_PosY = l_getMersenneInteger(0,width-1)

        r,g,b = l_checkMap(Ore_PosX, Ore_PosY)

        if ( r == Planet_Red and g == Planet_Green and b == Planet_Blue ) then
            l_modifyMap(Ore_PosX,Ore_PosY,Ore_Red,Ore_Green,Ore_Blue)
            Ore = Ore - 1
        end
    end
end
