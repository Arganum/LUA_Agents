-- Global variables:
Explorer_PosX = 0   --autons X position
Explorer_PosY = 0   --autons Y position
ID = 0              --autons ID
macroF = 0          --simulations macrofactor
timeRes = 0         --simulations time resolution.

envWidth = 0
envHeight = 0
scopeLenght = 11
angle = 0
cycle = 0
tableLimit = 32

state = "Idle"
newState = "Idle"
oldState = "Idle"

Battery = {}
timeScale = 1000000

-- Transporter Selection Variables:
BestTransporterID = 0
BestTransporterScore = 0
DistanceScale = 1.0 -- Distance Scale
BatteryScale = 1.0 -- Battery Scale
CapacityScale = 1.0 -- Capacity Scale

S_OreMemory = {}

I_Communication = 141

BatteryMax = 900
BatteryCurrent = 900
distOffset = 1 -- 1%? of Max Battery
wait = 3

perceptionCostP = 1
communicationCostI = 1
motionCostQ = 1
pickUpCost = 1

-- Explorer Color
Explorer_Red    =  84
Explorer_Green  =  36
Explorer_Blue   =  55

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

-- Base Color
Base_Red    = 217
Base_Green  =  91
Base_Blue   =  67

-- Base Coordinates
Base_PosX   = 0
Base_PosY   = 0
Base_ID     = 0

-- Init of the lua Explorer, function called upon initilization of the LUA auton:
function initAgent(x, y, id, macroFactor, timeResolution)

    Explorer_PosX = x
    Explorer_PosY = y
    ID = id
    macroF = macroFactor
    timeRes = timeResolution

    loadBaseCoordinates()
    Explorer_PosX = l_getMersenneInteger(Base_PosX-41,Base_PosX+41)
    Explorer_PosY = l_getMersenneInteger(Base_PosY-41,Base_PosY+41)

    while ( collisionCheckInit(Explorer_PosX, Explorer_PosY) == true ) do
        Explorer_PosX = l_getMersenneInteger(Base_PosX-41,Base_PosX+41)
        Explorer_PosY = l_getMersenneInteger(Base_PosY-41,Base_PosY+41)
    end

    envWidth, envHeight = l_getEnvironmentSize()

    --colorExplorer()

    newState = "Move"
    updateState()

    l_debug("Explorer #: " .. id .. " has been initialized")
end

-- Event Handling:
function handleEvent(origX, origY, origID, origDesc, origTable)
    --make a response:
    --l_debug(ID.." : "..origDesc )
    if origID >= Base_ID and origID < Base_ID + 8 then
        if origDesc == "Available" then
            load("ctable="..origTable)()
            if distTorus(origX, origY, Explorer_PosX, Explorer_PosY) < I_Communication then
                Score = calculateScore(ctable[1], ctable[2], ctable[3])

                if ( Score > BestTransporterScore ) then
                    BestTransporterID = origID
                    BestTransporterScore = Score
                    --l_debug(Score)
                end
            end
        end
    end

    return 0,0,0,"null"
end

--Determine whether or not this Auton will initiate an event.
function initiateEvent()
        --print(state)

        if state == "Move" then
            moveRandom()
            newState = "Perception"
        end

        if state == "Perception" then
            perceptionScope(Explorer_PosX, Explorer_PosY)
            cycle = cycle - 1
            if cycle <= 0 and #S_OreMemory < tableLimit then
                newState = "Move"
            elseif cycle <= 0 then
                newState = "OreCoordinatesReady"
            end
        end

        if state == "OreCoordinatesReady" then
            --BatteryCurrent = BatteryCurrent - communicationCostI
            newState = "Wait"
            cycle = wait
            s_calltable = "empty"
            desc = "OreCoordinatesReady"
            propagationSpeed = 50000
            targetID = 0;

            updateState()
            return propagationSpeed, s_calltable, desc, targetID
        end

        if state == "PickBestTransporter" then
            --BatteryCurrent = BatteryCurrent - communicationCostI
            s_S_OreMemory = serializeTbl(S_OreMemory)
            desc = "OreMemory"
            propagationSpeed = 50000
            targetID = BestTransporterID;
            clearTable()
            BestTransporterID = 0
            BestTransporterScore = 0
            newState = "Move"

            updateState()
            return propagationSpeed, s_S_OreMemory, desc, targetID
        end

        if state == "Wait" then
            if BestTransporterID ~= 0 and BestTransporterScore ~= 0 then
                newState = "PickBestTransporter"
            elseif BestTransporterID == 0 and BestTransporterScore == 0 then
                cycle = cycle - 1
                if(cycle <= 0) then
                    newState = "OreCoordinatesReady"
                end
            end
        end

        if distTorus(Explorer_PosX, Explorer_PosY, Base_PosX, Base_PosY) * distOffset > BatteryCurrent then -- Maybe dead state should be in the if statement
            newState = "Survival Mode"
            if state ~= "Survival Mode" then
                oldState = state
            end
        end

        if state == "Survival Mode" then
            charged = false
            moveAroundObstacle(Base_PosX, Base_PosY)
            for i = -3, 2, 1 do
                for j = -3, 2, 1 do
                    red, green, blue = l_checkMap(Explorer_PosX + i,Explorer_PosY + j)
                    if (( red == Base_Red ) and ( green == Base_Green ) and ( blue == Base_Blue ) and charged == false) then
                        BatteryCurrent = BatteryMax
                        charged = true
                        i = 2
                        j = 2
                        newState = oldState
                    elseif BatteryCurrent == 0 then
                        newState = "Dead"
                    end
                end
            end
        end

        if BatteryCurrent <= 0 then
            newState = "Dead"
        end

        if state == "Dead" then
            colorDeadExplorer()
        end

        updateState()

        if l_currentTime()%timeScale == 0 then
            table.insert(Battery,  BatteryCurrent)
        end

        return 0,0,0,"null"
end


function getSyncData()
    return Explorer_PosX, Explorer_PosY
end

function simDone()
    file = io.open("Explorer_" .. ID .. "_Battery.csv","w")
    for i,v in pairs(Battery) do
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

function updateState()
    state = newState
end

function loadBaseCoordinates()
    file = io.open("Base_CoordinateX.lua", "r")
    io.input(file)
    Base_PosX = io.read("*number")
    --l_debug(Base_PosX)
    io.close(file)

    file = io.open("Base_CoordinateY.lua", "r")
    io.input(file)
    Base_PosY = io.read("*number")
    --l_debug(Base_PosY)
    io.close(file)

    file = io.open("Base_ID.lua", "r")
    io.input(file)
    Base_ID = io.read("*number")
    --l_debug(Base_ID)
    io.close(file)
end

function colorExplorer()
    for i = -2, 1, 1 do
        for j = -2, 1, 1 do
            l_modifyMap(Explorer_PosX+i,Explorer_PosY+j,Explorer_Red,Explorer_Green,Explorer_Blue)
        end
    end
end

function colorDeadExplorer()
    for i = -2, 1, 1 do
        for j = -2, 1, 1 do
            if collisionCheckInit(Explorer_PosX+i,Explorer_PosY+j) == false then
                l_modifyMap(Explorer_PosX+i,Explorer_PosY+j,Explorer_Red,Explorer_Green,Explorer_Blue)
            end
        end
    end
end

function collisionCheckInit(posX, posY)
    agentsatpos = l_checkCollision(posX,posY)

    red, green, blue = l_checkMap(posX,posY)

    if ( ( agentsatpos == true ) or ( red ~= Planet_Red ) and ( green ~= Planet_Green ) and ( blue ~= Planet_Blue ) ) then
        return true
    else
        return false
    end
end

function collisionCheck(posX, posY)
    agentsatpos = l_checkCollision(posX,posY)

    red, green, blue = l_checkMap(posX,posY)

    if ( ( agentsatpos == true ) or (red ~= Planet_Red and Base_Red) and (green ~= Planet_Green and Base_Green) and (blue ~= Planet_Blue and Base_Blue) ) then
        return true, posX, posY
    else
        return false, posX, posY
    end
end

function calculateScore( Distance, Battery, Capacity )

    Score = Battery*BatteryScale + Capacity*CapacityScale - Distance*DistanceScale

    return Score
end

function distTorus(refPosX, refPosY, desPosX, desPosY)

    width, height = l_getEnvironmentSize()
    width = width + 1
    height = height + 1
    distWtorus = math.sqrt(math.pow(math.min(math.abs(refPosX - desPosX), width - math.abs(refPosX - desPosX)),2) + math.pow(math.min(math.abs(refPosY - desPosY), height - math.abs(refPosY - desPosY)),2))
    distWtorus = math.floor(distWtorus + 0.5)

    return distWtorus
end

function clearTable()
    for i in pairs(S_OreMemory) do
        S_OreMemory[i] = nil
        --print(table[i])
    end
end

function moveRandom()

    newPosX = Explorer_PosX + l_getMersenneInteger(0,2)-1;
    newPosY = Explorer_PosY + l_getMersenneInteger(0,2)-1;

    newPosX, newPosY = moveTorus(newPosX, newPosY)

    --l_debug(newPosX..":"..newPosY)
    --l_modifyMap(newPosX, newPosY,0,0,255)

    --l_debug("moving from X"..posX..", Y"..posY)
    l_updatePosition(Explorer_PosX, Explorer_PosY, newPosX, newPosY,ID)
    Explorer_PosX = newPosX
    Explorer_PosY = newPosY

    BatteryCurrent = BatteryCurrent - motionCostQ
end

function moveTorus(newPosX, newPosY)

    if newPosX > envWidth then
            newPosX = newPosX - envWidth
    end

    if newPosX < 0 then
            newPosX = newPosX + envWidth
    end

    if newPosY < 0 then
            newPosY = newPosY + envHeight
    end

    if newPosY > envHeight then
            newPosY = newPosY - envHeight
    end

    return newPosX, newPosY

end

function perceptionScope(refPosX, refPosY)

    if(scopeLenght == 1) then
        mapTenthArea = math.sqrt((((envWidth + 1) * (envHeight + 1)) / 100))
        --perception = math.sqrt(l_getMersenneInteger(1, mapTenthArea))
        scopeLenght = mapTenthArea
    end

    radian = angle
    newRadian = radian

    for lookout = 1, scopeLenght, 1 do
        for Around = 1, (lookout * 8), 1 do
            subradian = math.pi * ((360/(lookout * 8)) / 180)

            newRadian = newRadian + subradian

            searchPosX = refPosX + lookout * math.cos(newRadian)
            searchPosY = refPosY + lookout * math.sin(newRadian)
            searchPosX = math.floor(searchPosX + 0.5)
            searchPosY = math.floor(searchPosY + 0.5)

            searchPosX, searchPosY = moveTorus(searchPosX, searchPosY)

            oreFound, orePosX, orePosY = findOres(searchPosX, searchPosY)

            if(oreFound == true and #S_OreMemory < tableLimit ) then
                l_debug("Found an Ore at pos: " .. orePosX .. " , " .. orePosY .. " ")
                l_modifyMap(orePosX, orePosY,255,0,0)
                table.insert(S_OreMemory, orePosX)
                table.insert(S_OreMemory, orePosY)
            end
        end
    end

    BatteryCurrent = BatteryCurrent - perceptionCostP
    cycle = perceptionCostP
end

function findOres(OreposX, OreposY)
-- Made for the Transporteres, to be sudden that they have
-- found an ore and it has not been collected since the
-- explorer found it

    red, green, blue = l_checkMap(OreposX, OreposY)

    if((red == Ore_Red) and (green == Ore_Green) and (blue == Ore_Blue)) then
        return true, OreposX, OreposY
    else
        return false, OreposX, OreposY
    end

end

function moveAroundObstacle(desX, desY)

    torusdesX = desX
    torusdesY = desY

    if((desX - Explorer_PosX) > (envWidth/2)) then
        torusdesX = torusdesX - envWidth
    elseif ((Explorer_PosX - desX) > (envWidth/2)) then
        torusdesX = envWidth + torusdesX
    end

    if((desY - Explorer_PosY) > (envHeight/2)) then
        torusdesY = torusdesY - envHeight
    elseif ((Explorer_PosY - desY) > (envHeight/2)) then
        torusdesY = envHeight + torusdesY
    end

    desX = torusdesX
    desY = torusdesY

    angle = math.atan2(desY - Explorer_PosY, desX - Explorer_PosX);

    vX = 1 * math.cos(angle);
    vY = 1 * math.sin(angle);

    newPosX = vX + Explorer_PosX;
    newPosY = vY + Explorer_PosY;

    newPosX, newPosY = moveTorus(newPosX, newPosY)

    inCollision, obsPosX, obsPosY = collisionCheck(newPosX, newPosY)
    if(inCollision == true) then
        newPosX, newPosY = lookAround(obsPosX, obsPosY, Explorer_PosX, Explorer_PosY)
        newPosX, newPosY = moveTorus(newPosX, newPosY)
    end

    --l_debug(newPosX..":"..newPosY)
    --l_modifyMap(newPosX, newPosY,0,0,255)

    --l_debug("moving from X"..posX..", Y"..posY)
    l_updatePosition(Explorer_PosX, Explorer_PosY, newPosX, newPosY,ID)
    Explorer_PosX = newPosX
    Explorer_PosY = newPosY

    BatteryCurrent = BatteryCurrent - motionCostQ

    Explorer_PosX = math.floor(Explorer_PosX + 0.5)
    Explorer_PosY = math.floor(Explorer_PosY + 0.5)
    --l_debug("Desired position: " .. desX .. " , " .. desY .. " ")
    --l_debug("Actual position: " .. posX .. " , " .. posY .. " ")
end

function lookAround(obsPosX, obsPosY, posX, posY)

       obsPosX = math.floor(obsPosX + 0.5)
       obsPosY = math.floor(obsPosY + 0.5)
       refPosX = math.floor(posX + 0.5)
       refPosY = math.floor(posY + 0.5)

       radian = angle
       newRadian = radian

       for lookout = 1, scopeLenght, 1 do
        for Around = 1, (lookout * 8), 1 do
           subradian = math.pi * ((360/(lookout * 8)) / 180)

           newRadian = newRadian + subradian

           obsPosX = refPosX + lookout * math.cos(newRadian)
           obsPosY = refPosY + lookout * math.sin(newRadian)
           obsPosX = math.floor(obsPosX + 0.5)
           obsPosY = math.floor(obsPosY + 0.5)

           inCollision, obsPosX, obsPosY = collisionCheck(obsPosX, obsPosY)

           if(inCollision == false) then
            return obsPosX, obsPosY
           end

        end
       end
end



