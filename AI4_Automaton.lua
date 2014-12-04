-- Global variables:
posX = 0 	--autons X position
posY = 0	--autons Y position
ID  = 0		--autons ID
macroF = 0	--simulations macrofactor
timeRes = 0	--simulations time resolution.

nodeList = {0,0,0,0}

timePeriod = 1000
halfPeriod_1 = 500
halfPeriod_2 = 500
switchTime = 0

direction = "east&west"
formerDirection = "north&south"

-- Base Color
BaseRed    = 217
BaseGreen  =  91
BaseBlue   =  67

-- Planet Color
PlanetRed      = 236
PlanetGreen    = 208
PlanetBlue     = 120

-- Ore Color
OreRed         =  83
OreGreen       = 119
OreBlue        = 122

-- Explorer Color
ExplorerRed    =  84
ExplorerGreen  =  36
ExplorerBlue   =  55

-- Init of the lua Base, function called upon initilization of the LUA auton:
function initAgent(x, y, id, macroFactor, timeResolution, list)

    posX = x
    posY = y
    ID = id
    macroF = macroFactor
    timeRes = timeResolution
    nodeList = list

    colorAutomaton()

    colorGreen(4, 0)
    colorGreen(-4, 0)
    colorRed(0, 4)
    colorRed(0, -4)

    direction = "east&west"
    formerDirection = "north&south"

    l_debug("Automaton #: " .. id .. " has been initialized")

end

-- Event Handling:
function handleEvent(origX, origY, origID, origDesc, origTable)
    --make a response:
    if ID == 1 then
        l_debug(ID.." : "..origDesc .. " : " .. origID )
    end
    return 0,0,0,"null"
end

--Determine whether or not this Auton will initiate an event.
function initiateEvent()
    switchCircuit()

    if direction == "east&west" then
        key = l_getMersenneInteger(1,2)
        --l_debug(key)
    elseif direction == "north&south" then
        key = l_getMersenneInteger(3,4)
        --l_debug(key)
    end

    receiverNode = nodeList[key]

    if receiverNode ~= 0 and (direction ~= formerDirection) then
        formerDirection = direction
        calltable = {"stuff", "junk"}
        s_calltable = serializeTbl(calltable)
        desc = "Package"
        propagationSpeed = 50000

        targetID = receiverNode;

        return propagationSpeed, s_calltable, desc, targetID
    end

    return 0,0,0,"null"
end


function getSyncData()
    return posX, posY
end

function simDone()
    l_debug("Automaton #: " .. ID .. " is done\n")
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

function colorAutomaton()
    for i = -2, 1, 1 do
        for j = -2, 1, 1 do
            l_modifyMap(posX+i,posY+j,ExplorerRed,ExplorerGreen,ExplorerBlue)
        end
    end
end

function colorGreen(g_x, g_y)
    for i = -2, 1, 1 do
        for j = -2, 1, 1 do
            l_modifyMap(g_x+posX+i,g_y+posY+j,OreRed,OreGreen,OreBlue)
        end
    end
end

function colorRed(r_x, r_y)
    for i = -2, 1, 1 do
        for j = -2, 1, 1 do
            l_modifyMap(r_x+posX+i,r_y+posY+j,BaseRed,BaseGreen,BaseBlue)
        end
    end
end

function switchCircuit()
    if switchTime == timePeriod then
        colorGreen(0, 4)
        colorGreen(0, -4)
        colorRed(4, 0)
        colorRed(-4, 0)
        direction = "north&south"
        switchTime = 0
    elseif switchTime > halfPeriod_1 then
        colorGreen(0, 4)
        colorGreen(0, -4)
        colorRed(4, 0)
        colorRed(-4, 0)
        direction = "north&south"
    elseif switchTime <= halfPeriod_2 then
        colorGreen(4, 0)
        colorGreen(-4, 0)
        colorRed(0, 4)
        colorRed(0, -4)
        direction = "east&west"
    end

    switchTime = switchTime + 1
end
