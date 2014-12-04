-- Global variables:
posX = 0                -- autons X position
posY = 0                -- autons Y position
ID = 0                  -- autons ID
macroF = 0              -- simulations macrofactor
timeRes = 0             -- simulations time resolution.

-- IDM parameters
desiredSpeed = 20        -- the desired speed of the car in km/h
timeHeadway = 1.5         -- the time headway to the leading car in seconds
minGab = 2.0              -- the minimum gab kept at complete standstill in meters
acceleration = 0.3        -- the car acceleration in m/s^2
breaking = 3.0            -- the car deceleration in m/s^2
constAccDec = 0         -- the constant term 2*Sqrt(a*b) of the sStar function
sigma = 4.0             -- sigma(smallDelta) for the IDM model 

-- Internal Car parameters
currSpeed = 0   -- Current Speed of the Car in km/h
prevSpeed = 0   -- Previous Spped of the Car in km/h
prevTime = 0   -- Previous Time Step in seconds
currDist = 0    -- Current Distance position of the Car in meters
currGab = 0   -- Current Gab to the leading Car in meters
carLenght = 2.0   -- Car Lenght in meters

-- Leading Car parameters
tempGab = 0
newGab = 0

-- Init of the lua Transporter, function called upon initilization of the LUA auton:
function initAuton(x, y, id, macroFactor, timeResolution)

    posX = 10 -- x
    posY = 50 -- y
    ID = id
    macroF = macroFactor
    timeRes = timeResolution

    constAccDec = 2 * math.sqrt( acceleration * breaking )

    -- distWtorus = math.sqrt(math.pow(math.min(math.abs(refPosX - desPosX), 
    -- width - math.abs(refPosX - desPosX)),2) + math.pow(math.min(math.abs(refPosY - desPosY), 
    -- height - math.abs(refPosY - desPosY)),2))

    l_debug("Car #: " .. id .. " has been initialized")
end

-- Event Handling:
function handleEvent(origX, origY, origID, origDesc, origTable)
    -- make a response:
    -- l_debug(ID.." : "..origDesc )
    return 0,0,0,"null"
end

-- Determine whether or not this Auton will initiate an event.
function initiateEvent()
  
    if newGab == 0 then
      currGab = 1000
    elseif newGab > 0 then
      currGab = newGab
    end

    --l_debug( "Time: " .. l_currentTime() )

    --l_debug( "Star: " .. sStar() )

    --l_debug( "Calc: " .. calculateIDM() )

    updateIDM()
    
    tempGab = 0
    newGab = 0
    
    updatePosition() -- Write, test first for just x?

    l_debug( "Current Speed: " .. currSpeed )

    calltable = {carLenght}
    s_calltable = serializeTbl(calltable)
    desc = "infoIDM"
    propagationSpeed = 50000
    targetID = ID
    return propagationSpeed, s_calltable, desc, targetID

end


function getSyncData()
    return posX,  posY
end

function simDone()
    l_debug("Agent #: " .. ID .. " is done\n")
end

function serializeTbl(val, name, depth)
    -- skipnewlines = skipnewlines or false
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

function sStar()
        return ( minGab + math.max( 0 , ( currSpeed * timeHeadway + ( currSpeed * ( currSpeed - prevSpeed ) ) / constAccDec ) ) )
end

-- Calculate the acceleration of the IDM
function calculateIDM()
    return ( acceleration * ( 1 - math.pow( ( currSpeed / desiredSpeed ), sigma ) - math.pow( ( sStar() / currGab ), 2 ) ) )
end

-- 'Integration' of the IDM
function updateIDM()
    newAccIDM = calculateIDM()
    newTime = l_currentTime()
    deltaTime = ( newTime - prevTime ) / 10000
    --l_debug( "Time: " .. deltaTime )
    newSpeed = currSpeed + newAccIDM * deltaTime
    newDist = currSpeed * deltaTime + 0.5 * newAccIDM * math.pow( deltaTime, 2 )

    currSpeed = newSpeed
    currDist = newDist
    prevTime = newTime

    -- newDist = currDist + currSpeed * deltaTime + 0.5 * newAccIDM * math.pow( deltaTime, 2 )
    -- newGab = 1 -- Can first update Gab (newGab) after Leading Car has moved. Send information in the beginning of the time cycle instead of in the end.

    --return newSpeed, newPrevSpeed, newPrevTime, newDist -- newGab?
end

function updatePosition()
    l_debug( "PosX: " .. posX )
    l_debug( "Dist: " .. currDist )
    if ( posX + currDist ) > 1999 then
        posX = ( posX + currDist ) - 1999
    else
        posX = posX + currDist -- cos(direction)*currDist
        posY = posY -- sin(direction)*currDist
    end
end
