local vector3 = {}
vector3.__index = vector3
---@param self Vector3
vector3.__tostring = function(self)
    return ("x : %f, y : %f, z : %f"):format(self.x,self.y,self.z)
end
--//Types//--
---@class Vector3
---@field x number
---@field y number
---@field z number
---@field clone fun(self : Vector3) : Vector3
---@field dot fun(self : Vector3,v1 : Vector3) : number
---@field cross fun(self : Vector3,v1 : Vector3) : Vector3 
---@field normalize fun(self : Vector3) : Vector3 
---@field getMagnitude fun(self : Vector3) : number
---@field round fun(self : Vector3) : Vector3
---@field hasNegativeField fun(self : Vector3) : boolean
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

--//Modules//--
local round = require('Functionnal.round')
--//Methods//--

--<b>Vector3</b> constructor
---@param x number?
---@param y number?
---@param z number?
---@return Vector3
function vector3.new(x,y,z)
    local self = setmetatable({},vector3)
    self.x = x or 0
    self.y = y or 0
    self.z = z or 0
    return self
end
---@param self Vector3
---@return Vector3
function vector3.clone(self)
    return vector3.new(self.x,self.y,self.z)
end
---@param self Vector3
---@return number
function vector3.getMagnitude(self)
    return math.sqrt(self.x^2 + self.y^2 + self.z^2)
end
---@param self Vector3
function vector3.round(self)
    self.x = round(self.x)
    self.y = round(self.y)
    self.z = round(self.z)
    return self
end
---@param self Vector3
---@return Vector3
function vector3.normalize(self)
    local magnitude = self:getMagnitude()
    if magnitude == 0 then
        return self:clone()
    end
    return vector3.new(
        self.x/magnitude,
        self.y/magnitude,
        self.z/magnitude
    )
end

---@param self Vector3
---@return boolean
function vector3.hasNegativeField(self)
    return self.x < 0 or self.y < 0 or self.z < 0
end

---@param self Vector3
---@param v1 Vector3
---@return Vector3
function vector3.cross(self,v1)
    return vector3.new(
        (self.y * v1.z) - (self.z * v1.y),
        (self.z * v1.x) - (self.x * v1.z),
        (self.x * v1.y) - (self.y * v1.x)
    )
end
---@param self Vector3
---@param v1 Vector3
---@return number
function vector3.dot(self,v1)
    return self.x * v1.x + self.y * v1.y + self.z * v1.z
end

---@type fun(... : Vector3): Vector3,Vector3[]
function vector3.minY(...)
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



return vector3