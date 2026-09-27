local vector2 = {}
vector2.__index = vector2
---@param self Vector2
vector2.__tostring = function(self)
    return ("x : %f, y : %f"):format(self.x,self.y)
end
--//Types//--
---@class Vector2
---@field x number
---@field y number
---@field round fun(self : Vector2) : Vector2
---@field hasNegativeField fun(self : Vector2) : boolean

--//Modules//--
local round = require('Functionnal.round')
--//Constants//--

--//Variables//--

--//Private Functions//--

---@generic T
---@param array T[]
---@param handle T[]
---@return number?
local function find(array,handle)
    local index
    for i,value in pairs(array) do
        if value == handle then
            index = i
        end
    end
    return index
end

--//Methods//--

--<b>Vector2</b> constructor
---@param x number?
---@param y number?
---@return Vector2
function vector2.new(x,y)
    local self = setmetatable({},vector2)
    self.x = x or 0
    self.y = y or 0
    return self
end

---@param self Vector2
function vector2.round(self)
    self.x = round(self.x)
    self.y = round(self.y)
    return self
end

---@type fun(... : Vector2): Vector2,Vector2[]
function vector2.maxY(...)
    local args = {...}
    local maxYVector = args[1]
    for _,vector in pairs(args) do
        if vector.y > maxYVector.y then
            maxYVector = vector
        end
    end
    table.remove(args,find(args,maxYVector))
    return maxYVector,args
end

---@type fun(... : Vector2): Vector2,Vector2[]
function vector2.minY(...)
    local args = {...}
    local minYVector = args[1]
    for _,vector in pairs(args) do
        if vector.y < minYVector.y then
            minYVector = vector
        end
    end
    table.remove(args,find(args,minYVector))
    return minYVector,args
end

---@param self Vector2
---@return boolean
function vector2.hasNegativeField(self)
    return self.x < 0 or self.y < 0
end

return vector2