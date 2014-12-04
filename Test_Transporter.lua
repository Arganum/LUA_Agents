-- Global variables:
Transporter_PosX = 0 	--autons X position
Transporter_PosY = 0 	--autons Y position
ID = 0                  --autons ID
macroF = 0              --simulations macrofactor
timeRes = 0             --simulations time resolution.

envWidth = 0
envHeight = 0
scopeLenght = 11
angle = 0
cycle = 0
tableLimit = 32

state = "Idle"
newState = "Idle"
oldState = "Idle"
allCollected = false

Battery = {}
OreCargo = {}
timeScale = 1000000

OreMemory = {}

I_Communication = 141

oreCapacity = 12
oreCollected = 0
BatteryMax = 9000
BatteryCurrent = 9000
distOffset = 1 -- 1%? of Max Battery
wait = 3

perceptionCostP = 1
communicationCostI = 1
motionCostQ = 1
pickUpCost = 1

-- Transporter Color
Transporter_Red    =  84
Transporter_Green  =  36
Transporter_Blue   =  55

-- Planet Color
Planet_Red      = 236
Planet_Green    = 208
Planet_Blue     = 120

-- Ore Color
Ore_Red         =  83
Ore_Green       = 119
Ore_Blue        = 122

OreXCoor        =   0
OreYCoor        =   0

-- Found Ore Color
Ore_Red_F       = 255
Ore_Green_F     =   0
Ore_Blue_F      =   0

-- Base Color
Base_Red    = 217
Base_Green  =  91
Base_Blue   =  67

-- Base Coordinates
Base_PosX   = 0
Base_PosY   = 0
Base_ID     = 0

-- Init of the lua Transporter, function called upon initilization of the LUA auton:
function initAgent(x, y, id, macroFactor, timeResolution)

    Transporter_PosX = x
    Transporter_PosY = y
    ID = id
    macroF = macroFactor
    timeRes = timeResolution

    loadBaseCoordinates()
    Transporter_PosX = l_getMersenneInteger(Base_PosX-41,Base_PosX+41)
    Transporter_PosY = l_getMersenneInteger(Base_PosY-41,Base_PosY+41)

    while ( collisionCheckInit(Transporter_PosX, Transporter_PosY) == true ) do
        Transporter_PosX = l_getMersenneInteger(Base_PosX-41,Base_PosX+41)
        Transporter_PosY = l_getMersenneInteger(Base_PosY-41,Base_PosY+41)
    end

    --colorTransporter()

    envWidth, envHeight = l_getEnvironmentSize()

    newState = "Available"
    updateState()

    l_debug("Transporter #: " .. id .. " has been initialized")
end

-- Event Handling:
function handleEvent(origX, origY, origID, origDesc, origTable)
    --make a response:
    --l_debug(ID.." : "..origDesc )
    if origID >= Base_ID and origID < Base_ID + 8 then
        if origDesc == "OreAccepted" and state == "OreDelivery" and origID == Base_ID then
            if distTorus(origX, origY, Transporter_PosX, Transporter_PosY) < I_Communication then
                load("ctable="..origTable)()
                oreCollected = oreCollected - ctable[1]
                newState = "CheckMemory"
            end
        end

        if origDesc == "OreRejected" and state == "OreDelivery" and origID == Base_ID then
            if distTorus(origX, origY, Transporter_PosX, Transporter_PosY) < I_Communication then
                newState = "Unavailable"
            end
        end

        if origDesc == "OreCoordinatesReady" and state == "Available" then
            Distance, BatteryCurrent, CC_CapacityCurrent = transInfo(origX, origY, Transporter_PosX, Transporter_PosY)
            if Distance < I_Communication then
                --BatteryCurrent = BatteryCurrent - communicationCostI
                calltable = {Distance, BatteryCurrent, CC_CapacityCurrent}
                s_calltable = serializeTbl(calltable)
                desc = "Available"
                propagationSpeed = 50000
                targetID = origID
                updateState()
                return propagationSpeed, s_calltable, desc, targetID
            end
        end

        if origDesc == "OreMemory" and state == "Available" then
            load("OreMemory="..origTable)()

            for i = 1, #OreMemory, 1 do
                --l_debug("Pickedup an Ore at pos: " .. OreMemory[i] .. " , ")
            end

            allCollected = false
            OreXCoor, OreYCoor, OreCoor = nextCoordinate()
            l_debug("OreToBePickedUp: " ..OreXCoor.. " , " ..OreYCoor.. " ")

            newState = "PickUpOres"
        end

        updateState()
    end

    return 0,0,0,"null"
end

--Determine whether or not this Auton will initiate an event.
function initiateEvent()

    if state == "PickUpOres" then
        if allCollected == false then
            if Transporter_PosX == OreXCoor and Transporter_PosY == OreYCoor then
                --l_debug("OreMemory: " ..#OreMemory.. " ")
                --l_debug("OrePickUp: " ..Transporter_PosX.. " , " ..Transporter_PosY.. " ")
                pickUp(Transporter_PosX, Transporter_PosY)
                if #OreMemory == 0 then
                    allCollected = true
                else
                    OreXCoor, OreYCoor, OreCoor = nextCoordinate()
                    --l_debug("OreToBePickedUp: " ..OreXCoor.. " , " ..OreYCoor.. " ")
                end
            end
            moveAroundObstacle(OreXCoor, OreYCoor)
        elseif oreCollected == oreCapacity then
            newState = "MoveToBase"
        elseif #OreMemory == 0 then
            newState = "Available"
        end
    end

    if state == "CheckMemory" then
        if #OreMemory ~= 0 then
            newState = "PickUpOres"
        elseif #OreMemory == 0 then
            newState = "Available"
        end
    end

    if state == "OreDelivery" then
        calltable = {[1] = oreCollected}
        s_calltable = serializeTbl(calltable)
        desc = "OreDelivery"
        propagationSpeed = 50000
        targetID = Base_ID
        updateState()
        return propagationSpeed, s_calltable, desc, targetID
    end

    if state == "MoveToBase" then
        arived = false
        moveAroundObstacle(Base_PosX, Base_PosY)
        for i = -3, 2, 1 do
            for j = -3, 2, 1 do
                red, green, blue = l_checkMap(Transporter_PosX + i, Transporter_PosY + j)
                if (( red == Base_Red ) and ( green == Base_Green ) and ( blue == Base_Blue ) and arived == false) then
                    BatteryCurrent = BatteryMax
                    arived = true
                    i = 2
                    j = 2
                    newState = "OreDelivery"
                end
            end
        end
    end

    if distTorus(Transporter_PosX, Transporter_PosY, Base_PosX, Base_PosY) * distOffset > BatteryCurrent then -- Maybe dead state should be in the if statement
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
                red, green, blue = l_checkMap(Transporter_PosX + i, Transporter_PosY + j)
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
        colorDeadTransporter()
    end

    updateState()

    if l_currentTime()%timeScale == 0 then
        table.insert(Battery,  BatteryCurrent)
        table.insert(OreCargo,  oreCollected)
    end
    return 0,0,0,"null"
end


function getSyncData()
        return Transporter_PosX,  Transporter_PosY
end

function simDone()
    file = io.open("Transporter_" .. ID .. "_Battery.csv","w")
    for i,v in pairs(Battery) do
            file:write(i..","..v.."\n")
    end

    file:close()

    file = io.open("Transporter_" .. ID .. "_OreCargo.csv","w")
    for i,v in pairs(OreCargo) do
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

function colorTransporter()
    for i = -2, 1, 1 do
        for j = -2, 1, 1 do
            l_modifyMap(Transporter_PosX+i,Transporter_PosY+j,Transporter_Red,Transporter_Green,Transporter_Blue)
        end
    end
end

function colorDeadTransporter()
    for i = -2, 1, 1 do
        for j = -2, 1, 1 do
            if collisionCheckInit(Transporter_PosX+i,Transporter_PosY+j) == false then
                l_modifyMap(Transporter_PosX+i,Transporter_PosY+j,Transporter_Red,Transporter_Green,Transporter_Blue)
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

    if ( ( agentsatpos == true ) or ( red ~= Planet_Red and Base_Red ) and ( green ~= Planet_Green and Base_Green ) and ( blue ~= Planet_Blue and Base_Blue ) ) then
        if ( ( red ~= Ore_Red_F ) and ( green ~= Ore_Green_F ) and ( blue ~= Ore_Blue_F ) ) then
            return true, posX, posY
        end
    else
        return false, posX, posY
    end
end

function distTorus(refPosX, refPosY, desPosX, desPosY)

    width, height = l_getEnvironmentSize()
    width = width + 1
    height = height + 1
    distWtorus = math.sqrt(math.pow(math.min(math.abs(refPosX - desPosX), width - math.abs(refPosX - desPosX)),2) + math.pow(math.min(math.abs(refPosY - desPosY), height - math.abs(refPosY - desPosY)),2))
    distWtorus = math.floor(distWtorus + 0.5)

    return distWtorus
end

function moveTorus(torusPosX, torusPosY)

    if torusPosX > envWidth then
            torusPosX = torusPosX - envWidth
    end

    if torusPosX < 0 then
            torusPosX = torusPosX + envWidth
    end

    if torusPosY < 0 then
            torusPosY = torusPosY + envHeight
    end

    if torusPosY > envHeight then
            torusPosY = torusPosY - envHeight
    end

    return torusPosX, torusPosY

end

function moveAroundObstacle(desX, desY)

    torusdesX = desX
    torusdesY = desY

    if((desX - Transporter_PosX) > (envWidth/2)) then
        torusdesX = torusdesX - envWidth
    elseif ((Transporter_PosX - desX) > (envWidth/2)) then
        torusdesX = envWidth + torusdesX
    end

    if((desY - Transporter_PosY) > (envHeight/2)) then
        torusdesY = torusdesY - envHeight
    elseif ((Transporter_PosY - desY) > (envHeight/2)) then
        torusdesY = envHeight + torusdesY
    end

    desX = torusdesX
    desY = torusdesY

    angle = math.atan2(desY - Transporter_PosY, desX - Transporter_PosX);

    vX = 1 * math.cos(angle);
    vY = 1 * math.sin(angle);

    newonePosX = vX + Transporter_PosX;
    newonePosY = vY + Transporter_PosY;

    newonePosX = math.floor(newonePosX + 0.5)
    newonePosY = math.floor(newonePosY + 0.5)

    newtwoPosX, newtwoPosY = moveTorus(newonePosX, newonePosY)

    inCollision, obsPosX, obsPosY = collisionCheck(newtwoPosX, newtwoPosY)
    if(inCollision == true) then
        newthreePosX, newthreePosY = lookAround(obsPosX, obsPosY, Transporter_PosX, Transporter_PosY)
        newfourPosX, newfourPosY = moveTorus(newthreePosX, newthreePosY)
        newtwoPosX = newfourPosX
        newtwoPosY = newfourPosY
    end


    --l_debug(newPosX..":"..newPosY)
    --l_modifyMap(newtwoPosX, newtwoPosY,0,0,255)

    --l_debug("moving from X"..posX..", Y"..posY)
    l_updatePosition(Transporter_PosX, Transporter_PosY, newtwoPosX, newtwoPosY,ID)
    Transporter_PosX = newtwoPosX
    Transporter_PosY = newtwoPosY

    BatteryCurrent = BatteryCurrent - motionCostQ

    Transporter_PosX = math.floor(Transporter_PosX + 0.5)
    Transporter_PosY = math.floor(Transporter_PosY + 0.5)
    --l_debug("Desired position: " .. desX .. " , " .. desY .. " ")
    --l_debug("Actual position: " .. Transporter_PosX .. " , " .. Transporter_PosY .. " ")
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

function pickUp(desPosX, desPosY)

    Transporter_PosX = math.floor(Transporter_PosX + 0.5)
    Transporter_PosY = math.floor(Transporter_PosY + 0.5)
    desPosX = math.floor(desPosX + 0.5)
    desPosY = math.floor(desPosY + 0.5)

    oreRed, oreGreen, oreBlue = l_checkMap(desPosX, desPosY)
    if( ( oreRed == Ore_Red or Ore_Red_F ) and ( oreGreen == Ore_Green or Ore_Green_F ) and ( oreBlue == Ore_Blue or Ore_Blue_F ) and (oreCapacity - oreCollected) > 0) then
        if(Transporter_PosX == desPosX and Transporter_PosY == desPosY) then
            l_modifyMap(desPosX,desPosY,Planet_Red,Planet_Green,Planet_Blue)
            oreCollected = oreCollected + 1
            print(oreCollected)
            BatteryCurrent = BatteryCurrent - pickUpCost
        end
    end
end

function nextCoordinate()
    TempX = OreMemory[1]
    TempY = OreMemory[2]
    Coor = 1
    TempDist = distTorus(Transporter_PosX, Transporter_PosY, TempX, TempY)
    --l_debug("nCoor: " ..TempX.. " , " ..TempY.. " ")

    if ( #OreMemory ~= 2 ) then
        for i = 3, #OreMemory, 2 do
            CurrTempX = OreMemory[i]
            CurrTempY = OreMemory[i+1]
            --l_debug("nCoor: " ..CurrTempX.. " , " ..CurrTempY.. " ")
            CurrTempDist = distTorus(Transporter_PosX, Transporter_PosY, CurrTempX, CurrTempY)

            if TempDist > CurrTempDist then
                TempX = CurrTempX
                TempY = CurrTempY
                TempDist = CurrTempDist

                Coor = i
            end
        end
    end

    posX = TempX
    posY = TempY
    table.remove(OreMemory, Coor)
    table.remove(OreMemory, Coor)

    if ( #OreMemory == 0 ) then
        --l_debug("table empty")
    end

    return posX, posY, Coor
end

function transInfo(desPosX, desPosY, curPosX, curPosY)

    currentEnergi = BatteryCurrent
    currentCapacity = oreCapacity - oreCollected

    distDesBase = distTorus(desPosX, desPosY, Base_PosX, Base_PosY)
    distPosDes = distTorus(curPosX, curPosY, desPosX, desPosY)

    cirkel = 2 * scopeLenght * math.pi
    pickDistOffset = cirkel + distOffset

    totalJobDist = distDesBase + distPosDes + pickDistOffset

    if(currentEnergi > totalJobDist and currentCapacity ~= 0) then
        --l_debug("INFO: " .. distPosDes .. " , " .. currentEnergi .. " , " .. currentCapacity .. " ")
        return distPosDes, currentEnergi, currentCapacity
    else
        return 0, 0, 0
    end
end


