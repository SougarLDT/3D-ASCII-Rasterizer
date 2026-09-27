-- Make it so i can use ANSI escape code in classic window terminal
os.execute("reg add HKCU\\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1")
-- //Modules//--
local vector3 = require('Class.vector3')
local vector2 = require('Class.vector2')
local round = require('Functionnal.round')
local setWindowSize = require('Functionnal.setWindowSize')
local getCmdWindowSize = require('Functionnal.getCmdWindowSize')
local objParserClass = require('Class.ObjParser')
local askInput = require('Utility.askInput')
-- //Configurations//--
local path = "food.obj"
local INITIAL_ROTATIONS = vector3.new(0, 0, 180)
local ROTATION_SPEEDS = vector3.new(0, 50, 0)
local SHOW_VERTICES = false
local modelScaleFactor = 1.3
local SCALE_POSITION = vector2.new(0.5, 0.5)
local modelZPush = 10
-- //Constants//--
local DEFAULT_MODEL_SIZE = 100
local CAMERA_DIRECTION = vector3.new(0, 0, 1)
local BUFFER = {}
local LIGHT_LEVEL_SYMBOLS = ".,-~:;=!*#$@"
local SYMBOLS_LEN = #LIGHT_LEVEL_SYMBOLS
-- //Variables//--
local screen = {}
local zBuffer = {}
local fps = 144
local rows = nil -- y
local columns = nil -- x
local rotationX, rotationY, rotationZ = 0, 0, 0
local drawTimeElapsed = nil
local timePerFrame = nil
---@type Vector3[]
local modelVertices = nil
---@type number[][]
local modelTriangles = nil
---@type number[]
local zValues = {}
-- //Functions//--

---@param y number
---@param x0 number
---@param x1 number
---@param symbol string
---@param vertex Vector3
local function drawLine(y, x0, x1, symbol,vertex)
    local left = x0
    local right = x1
    if left > right then
        left = x1
        right = x0
    end
    if left == 0 then
        left = 1
    end
    for i = left, right do
        if not screen[y] or not screen[y][i] then
            goto continue
        end
        if zValues[vertex] >= zBuffer[y][i] then
            goto continue
        end
        zBuffer[y][i] = zValues[vertex]
        --[[
                if not screen[y] or zValues[] zBuffer[y][i] then
                goto continue
            end
        ]]
        screen[y][i] = symbol
        ::continue::
    end
end

---@param top Vector3
---@param bottom1 Vector2
---@param bottom2 Vector3
---@param symbol string
local function drawFlatBottom(top, bottom1, bottom2, symbol)
    local xBeginning = top.x
    local xEnd = top.x
    local yDisplacement = (top.y - bottom1.y)
    if yDisplacement == 0 then
        return
    end
    local side1Slope = -(top.x - bottom1.x) / yDisplacement
    local side2Slope = -(top.x - bottom2.x) / (top.y - bottom2.y)
    for y = round(top.y), round(bottom1.y) do
        drawLine(y, round(xBeginning), round(xEnd), symbol,top)
        xBeginning = xBeginning - side1Slope
        xEnd = xEnd - side2Slope
    end
    if SHOW_VERTICES then
        screen[top.y][top.x] = '%'
        screen[bottom1.y][bottom1.x] = '%'
        screen[bottom2.y][bottom2.x] = '%'
    end
end

---@param bottom Vector3
---@param top1 Vector2
---@param top2 Vector3
---@param symbol string
local function drawFlatTop(bottom, top1, top2, symbol)
    local xBeginning = bottom.x
    local xEnd = bottom.x
    local yDisplacement = (bottom.y - top1.y)
    if yDisplacement == 0 then
        return
    end
    local side1Slope = (bottom.x - top1.x) / (bottom.y - top1.y)
    local side2Slope = (bottom.x - top2.x) / (bottom.y - top2.y)
    for y = round(bottom.y), round(top1.y), -1 do
        drawLine(y, round(xBeginning), round(xEnd), symbol,bottom)
        xBeginning = xBeginning - side1Slope
        xEnd = xEnd - side2Slope
    end
    if SHOW_VERTICES then
        screen[bottom.y][bottom.x] = '%'
        screen[top1.y][top1.x] = '%'
        screen[top2.y][top2.x] = '%'
    end
end

---@param v1 Vector3
---@param v2 Vector3
---@param v3 Vector3
---@return Vector3,Vector3,Vector3
local function getTriangleDescendingYVertices(v1, v2, v3)
    local top0, vertices = vector3.minY(v1, v2, v3)
    local top1, vertices = vector3.minY(table.unpack(vertices))
    local top2 = vertices[1]
    return top0, top1, top2
end

---@param v1 Vector3
---@param v2 Vector3
---@param v3 Vector3
---@param symbol string
local function drawTriangle(v1, v2, v3, symbol)
    if v1:hasNegativeField() or v2:hasNegativeField() or v3:hasNegativeField() then
        return
    end
    local vertex1, vertex2, vertex3 = getTriangleDescendingYVertices(v1, v2, v3)
    local xMidpoint = round(vertex1.x + (vertex2.y - vertex1.y) / (vertex3.y - vertex1.y) * (vertex3.x - vertex1.x))
    local midpoint = vector2.new(xMidpoint, vertex2.y)
    drawFlatBottom(vertex1, midpoint, vertex2, symbol)
    drawFlatTop(vertex3, midpoint, vertex2, symbol)
end

---@param v1 Vector3
---@param origin Vector2
---@return Vector3
local function project2D(v1, origin)
    return vector3.new(v1.x / v1.z + origin.x, v1.y / v1.z + origin.y,v1.z):round()
end

---@param v1 Vector3
---@param angle number
---@return Vector3
local function rotateAroundY(v1, angle)
    return vector3.new(v1.x * math.cos(angle) + math.sin(angle) * v1.z, v1.y,
        v1.x * -math.sin(angle) + math.cos(angle) * v1.z)
end

---@param v1 Vector3
---@param angle number
---@return Vector3
local function rotateAroundX(v1, angle)
    return vector3.new(v1.x, v1.y * math.cos(angle) + -math.sin(angle) * v1.z,
        v1.y * math.sin(angle) + math.cos(angle) * v1.z)
end

---@param v1 Vector3
---@param angle number
---@return Vector3
local function rotateAroundZ(v1, angle)
    return vector3.new(v1.y * -math.sin(angle) + math.cos(angle) * v1.x,
        v1.y * math.cos(angle) + math.sin(angle) * v1.x, v1.z)
end

local function initialRotation()
    local rotatedVertices = {}
    for _, triangle in pairs(modelTriangles) do
        ---@type Vector3[]
        local transformedVertices = {}
        for i = 1, 3 do
            if rotatedVertices[triangle[i]] then
                goto continue
            end
            local xRot = math.rad(INITIAL_ROTATIONS.x)
            local yRot = math.rad(INITIAL_ROTATIONS.y)
            local zRot = math.rad(INITIAL_ROTATIONS.z)
            rotatedVertices[triangle[i]] = true
            transformedVertices[i] = modelVertices[triangle[i]]
            if xRot > 0 then
                transformedVertices[i] = rotateAroundX(transformedVertices[i], xRot)
            end
            if yRot > 0 then
                transformedVertices[i] = rotateAroundY(transformedVertices[i], yRot)
            end
            if zRot > 0 then
                transformedVertices[i] = rotateAroundZ(transformedVertices[i], zRot)
            end
            modelVertices[triangle[i]] = transformedVertices[i]
            ::continue::
        end
    end
end

---@param rx number  
---@param ry number
---@param rz number
local function draw3DModel(rx, ry, rz)
    for _, triangle in pairs(modelTriangles) do
        ---@type Vector3[]
        local transformedVertices = {}
        ---@type Vector3[]
        local unitVertices = {}
        for i = 1, 3 do
            transformedVertices[i] = modelVertices[triangle[i]]:clone()
            transformedVertices[i] = rotateAroundY(transformedVertices[i], ry)
            transformedVertices[i] = rotateAroundX(transformedVertices[i], rx)
            transformedVertices[i] = rotateAroundZ(transformedVertices[i], rz)
            unitVertices[i] = transformedVertices[i]:clone()
            local modelVertex =
                vector3.new(transformedVertices[i].x, transformedVertices[i].y, transformedVertices[i].z)
            local xValue = modelVertex.x
            local yValue = modelVertex.y
            local zValue = modelVertex.z
            local CUBE_SCALE = (rows + columns) * modelScaleFactor
            -- Push it into the screen
            transformedVertices[i].z = zValue + modelZPush
            -- Scale
            transformedVertices[i].x = xValue * CUBE_SCALE * 2
            transformedVertices[i].y = yValue * CUBE_SCALE
        end
        local transformedDisplacement1 = vector3.new((unitVertices[2].x - unitVertices[1].x),
            (unitVertices[2].y - unitVertices[1].y), (unitVertices[2].z - unitVertices[1].z))
        local transformedDisplacement2 = vector3.new((unitVertices[3].x - unitVertices[1].x),
            (unitVertices[3].y - unitVertices[1].y), (unitVertices[3].z - unitVertices[1].z))
        local normal = transformedDisplacement2:cross(transformedDisplacement1):normalize()
        -- Back face culling
        local dot = CAMERA_DIRECTION:dot(normal)
        if dot >= 0 then
            goto continue
        end
        ---@type Vector3[]
        local projectedPoints = {}
        for i = 1, 3 do
            projectedPoints[i] = project2D(transformedVertices[i],
                vector2.new(columns * SCALE_POSITION.x, rows * SCALE_POSITION.y))
        end
        local intensity = math.abs(dot)
        local lightLevel = round((SYMBOLS_LEN - 1) * intensity) + 1
        local symbol = LIGHT_LEVEL_SYMBOLS:sub(lightLevel, lightLevel)
        drawTriangle(projectedPoints[1], projectedPoints[2], projectedPoints[3], symbol)
        ::continue::
    end
end

local function displayScreen()
    BUFFER = {}
    BUFFER[1] = '\x1B'
    BUFFER[2] = '['
    BUFFER[3] = 'H'
    for row = 1, rows do
        local offset = 3 + (row - 1) * (columns + 1)
        for i = 1, columns do
            BUFFER[offset + i] = screen[row][i]
        end
        if row < rows then
            BUFFER[offset + columns + 1] = '\n'
        end
    end
    io.write(table.concat(BUFFER))
end

local function busy_wait(seconds)
    local start = os.clock()
    while os.clock() - start < seconds do
        -- Doing nothing just burning CPU cycles
    end
end

local function clearScreen()
    screen = {}
    for row = 1, rows do
        screen[row] = {}
        zBuffer[row] = {}
        for column = 1, columns do
            screen[row][column] = ' '
            zBuffer[row][column] = math.huge
        end
    end
end

---@param fps number
local function setTargetFps(fps)
    drawTimeElapsed = os.clock()
    timePerFrame = 1 / fps
end

---@return number
local function getDeltaTime()
    local deltaTime = os.clock() - drawTimeElapsed
    drawTimeElapsed = os.clock()
    local sleepTime = timePerFrame - deltaTime
    if sleepTime > 0 then
        busy_wait(sleepTime)
        ---@cast timePerFrame number
        return timePerFrame
    end
    return deltaTime
end

local function init()
    local dimensions = getCmdWindowSize()
    local width = askInput.askNumber("Enter window width", dimensions.width, 1, function()
        print("Width too small, fallback to auto")
    end)
    local height = askInput.askNumber("Enter window height", dimensions.height, 1, function()
        print("Height too small, fallback to auto")
    end)
    local modelPath = askInput.askString("Enter .obj model name (must be in the Resources folder)", path,
        objParserClass.validateObjPath):gsub(" ", "")
    local modelSize = askInput.askNumber("Enter 3D model size", DEFAULT_MODEL_SIZE)
    local modelXPostion = askInput.askNumber("Enter 3D model x scale position", SCALE_POSITION.x)
    local modelYPostion = askInput.askNumber("Enter 3D model y scale position", SCALE_POSITION.y)
    local zOffset = askInput.askNumber("Enter model distance from camera (higher = smaller & further away)", modelZPush,
        1, function()
            print("Distance too small, fallback to default")
        end)
    local rotationSpeedX = askInput.askNumber("Enter rotation speed X", ROTATION_SPEEDS.x)
    local rotationSpeedY = askInput.askNumber("Enter rotation speed Y", ROTATION_SPEEDS.y)
    local rotationSpeedZ = askInput.askNumber("Enter rotation speed Z", ROTATION_SPEEDS.z)
    local fpsInput = askInput.askNumber("Enter FPS", fps, 1)
    ---@cast modelPath string
    path = "Ressources/" .. modelPath
    SCALE_POSITION.x = modelXPostion
    SCALE_POSITION.y = modelYPostion
    ROTATION_SPEEDS.x = rotationSpeedX
    ROTATION_SPEEDS.y = rotationSpeedY
    ROTATION_SPEEDS.z = rotationSpeedZ
    modelZPush = zOffset
    modelScaleFactor = modelSize / 90
    fps = fpsInput
    rows = height
    columns = width
    local objParser = objParserClass.new(path):init()
    modelTriangles = objParser.triangles
    modelVertices = objParser.vertices
    setWindowSize(width, height)
    initialRotation()
    -- Clear terminal (and potentially hide cursor : x1B[?25l instead of x1B[?25h)
    io.write("\x1B[2J\x1B[?25h")
    -- Put cursor at top left corner (0,0)
    BUFFER[1] = '\x1B'
    BUFFER[2] = '['
    BUFFER[3] = 'H'
    setTargetFps(fps)
end
-- //Setup//--
init()
-- //Main Loop//--
while true do
    local delta = getDeltaTime()
    clearScreen()
    draw3DModel(rotationX, rotationY, rotationZ)
    rotationX = (rotationX + math.rad(ROTATION_SPEEDS.x * delta)) % (2 * math.pi)
    rotationY = (rotationY + math.rad(ROTATION_SPEEDS.y * delta)) % (2 * math.pi)
    rotationZ = (rotationZ + math.rad(ROTATION_SPEEDS.z * delta)) % (2 * math.pi)
    displayScreen()
end
