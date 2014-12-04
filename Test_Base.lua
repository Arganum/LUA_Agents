-- Global variables:
Base_PosX = 0 	--autons X position
Base_PosY = 0	--autons Y position
ID  = 0		--autons ID
macroF = 0	--simulations macrofactor
timeRes = 0	--simulations time resolution.

state = "Idle"

TotalOre = {}
OreFound = {}
Capacity = {}
timeScale = 1000000
OreFoundValue = 0
TotalOreValue = 0

M_Mode = 0
I_Communication = 41
S_OreMemory = 32
C_CapacityMax = 200
CC_CapacityCurrent = 0

-- Base Color
Base_Red    = 217
Base_Green  =  91
Base_Blue   =  67

-- Planet Color
Planet_Red      = 236
Planet_Green    = 208
Planet_Blue     = 120

-- Ore Color
Ore_Red         =  83
Ore_Green       = 119
Ore_Blue        = 122

-- Ore Color
Ore_Red_F       =  255
Ore_Green_F     =    0
Ore_Blue_F      =    0

-- Init of the lua Base, function called upon initilization of the LUA auton:
function initAgent(x, y, id, macroFactor, timeResolution)

    Base_PosX = x
    Base_PosY = y
    ID = id
    macroF = macroFactor
    timeRes = timeResolution

    height, width = l_getEnvironmentSize()

    Base_PosX = l_getMersenneInteger(19,height-20)
    Base_PosY = l_getMersenneInteger(19,width-20)

    while ( landingCollisionCheck(Base_PosX, Base_PosY) == true ) do
        Base_PosX = l_getMersenneInteger(19,height-20)
        Base_PosY = l_getMersenneInteger(19,width-20)
    end

    saveBaseCoordinates()
    colorBase()

    l_debug("Base #: " .. id .. " has been initialized")

end

-- Event Handling:
function handleEvent(origX, origY, origID, origDesc, origTable)
    --make a response:

    --l_debug(ID.." : "..origDesc )
    if origDesc == "OreDelivery" and state == "Idle" then
        load("ctable="..origTable)()
        if CC_CapacityCurrent + ctable[1] < C_CapacityMax then
            calltable = {[1] = ctable[1]}
            CC_CapacityCurrent = CC_CapacityCurrent + ctable[1]
        else
            calltable = {[1] = ( C_CapacityMax - CC_CapacityCurrent )}
            CC_CapacityCurrent = C_CapacityMax
        end
        desc = "OreAccepted"
        s_calltable = serializeTbl(calltable)
        propagationSpeed = 50000
        targetID = origID

        return propagationSpeed, s_calltable, desc, targetID
    end

    if origDesc == "OreDelivery" and state == "Capacity Full" then
        desc = "OreRejected"
        s_calltable = "empty"
        propagationSpeed = 50000
        targetID = origID

        return propagationSpeed, s_calltable, desc, targetID
    end

    return 0,0,0,"null"
end

--Determine whether or not this Auton will initiate an event.
function initiateEvent()
    if state == "Idle" and ( CC_CapacityCurrent == C_CapacityMax ) then
        state = "Capacity Full"
    end

    print(CC_CapacityCurrent)

    if l_currentTime()%timeScale == 0 then
        table.insert(Capacity,  CC_CapacityCurrent)
        if ID == 1 then
            height, width = l_getEnvironmentSize()
            for i = 0, height, 1 do
                for j = 0, width, 1 do
                    r, g, b = l_checkMap(i,j)
                    if r == Ore_Red and g == Ore_Green and b == Ore_Blue then
                        TotalOreValue = TotalOreValue + 1
                    end
                    if r == Ore_Red_F and g == Ore_Green_F and b == Ore_Blue_F then
                        TotalOreValue = TotalOreValue + 1
                        OreFoundValue = OreFoundValue + 1
                    end
                end
            end
            table.insert(TotalOre,  TotalOreValue)
            TotalOreValue = 0
            table.insert(OreFound,  OreFoundValue)
            OreFoundValue = 0
        end
    end

    return 0,0,0,"null"
end


function getSyncData()
        return Base_PosX, Base_PosY
end

function simDone()
    if ID == 1 then
        file = io.open("Base_" .. ID .. "_TotalOre.csv","w")
        for i,v in pairs(TotalOre) do
            file:write(i..","..v.."\n")
        end

        file:close()

        file = io.open("Base_" .. ID .. "_OreFound.csv","w")
        for i,v in pairs(OreFound) do
            file:write(i..","..v.."\n")
        end

        file:close()
    end

        file = io.open("Base_" .. ID .. "_Capacity.csv","w")
        for i,v in pairs(Capacity) do
            file:write(i..","..v.."\n")
        end

        file:close()

        l_debug("Agent #: " .. ID .. " is done\n")
end

function serializeTbl(val, name, depth)
        --skipnewlines = skipnewlines or false
        depth = depth or 0
        local tbl = string.rep("", depth)
        if name then
                if type(name)=="number" then
                        namestr = "["..name.."]"
                        tbl= tbl..namestr.."="
                elseif name then
                        tbl = tbl ..name.."="
                        --else tbl = tbl .. "systbl="
                end
        end
        if type(val) == "table" then
                tbl = tbl .. "{"
                local i = 1
                for k, v in pairs(val) do
                        if i ~= 1 then
                                tbl = tbl .. ","
                        end
                        tbl = tbl .. serializeTbl(v,k, depth +1)
                        i = i + 1;
                end
                tbl = tbl .. string.rep(" ", depth) ..  "}"
        elseif type(val) == "number" then
                tbl = tbl .. tostring(val)
        elseif type(val) == "string" then
                tbl = tbl .. string.format("%q", val)
        else
                tbl = tbl .. "[datatype not serializable:".. type(val) .. "]"
        end

        return tbl
end

function saveBaseCoordinates()
    file = io.open("Base_CoordinateX.lua", "w")
    io.output(file)
    io.write(Base_PosX)
    io.close(file)

    file = io.open("Base_CoordinateY.lua", "w")
    io.output(file)
    io.write(Base_PosY)
    io.close(file)

    file = io.open("Base_ID.lua", "w")
    io.output(file)
    io.write(ID)
    io.close(file)
end

function colorBase()
    for i = -2, 1, 1 do
        for j = -2, 1, 1 do
            l_modifyMap(Base_PosX+i,Base_PosY+j,Base_Red,Base_Green,Base_Blue)
        end
    end
end

function collisionCheck(posX, posY)
    agentsatpos = l_checkCollision(posX,posY)

    red, green, blue = l_checkMap(posX,posY)

    if ( ( agentsatpos == true ) or ( red ~= Planet_Red ) and ( green ~= Planet_Green ) and ( blue ~= Planet_Blue ) ) then
        return true
    else
        return false
    end
end

function landingCollisionCheck(posX, posY)
    collision = false
    for i = -3, 2, 1 do
        for j = -3, 2, 1 do

            if ( collisionCheck(posX+i,posY+j) == true ) then
                collision = true
            end
        end
    end

    return collision
end

function distTorus(refPosX, refPosY, desPosX, desPosY)

    width, height = l_getEnvironmentSize()
    width = width + 1
    height = height + 1
    distWtorus = math.sqrt(math.pow(math.min(math.abs(refPosX - desPosX), width - math.abs(refPosX - desPosX)),2) + math.pow(math.min(math.abs(refPosY - desPosY), height - math.abs(refPosY - desPosY)),2))
    distWtorus = math.floor(distWtorus + 0.5)

    return distWtorus
end
