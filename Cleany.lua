local Cleany = {}
Cleany.__index = Cleany

local FN_MARKER = newproxy(true)
local THREAD_MARKER = newproxy(true)

function Cleany.create()
    
    return setmetatable({
        _objects = {},
        _cleaning = false
    }, Cleany)

end

function Cleany:Add(object)
    assert(self._cleaning ~= true, "cleaning in process")

    local cleanupDetail = GetCleanupDetails(object)
    table.insert(self._objects, {
        Type = cleanupDetail,
        object = object
    })

    return object
end

function Cleany:AddTable(t)
    assert(type(t) == "table", `{t} is not a table; we got a {type(t)}`)

    for i, v in pairs(t) do
        if type(v) ~= "table" then
            self:Add(v)
        else
            self:AddTable(v)
        end
    end

end

function Cleany:Remove(object)
    assert(self._cleaning ~= true, "cleaning in process")

    for i, v in pairs(self._objects) do
        if v.object == object then
            self:__cleanupObject(v.object, v.Type)
            table.remove(self._objects, i)
        end
    end
end

function Cleany:Contruct(class, ...)
    assert(self._cleaning ~= true, "cleaning in proccess; cannot continue with contruct")

    if type(class) == "table" then
        local object = class.new(...)
        return self:Add(object)
    elseif type(class) == "function" then
        local object = class(...)
        return self:Add(object)
    end

end

function Cleany:AddMultiple(...)

    assert(self._cleaning ~= true, "cleaning in process")

    local items = {...}

    for _, item in pairs(items) do
        self:Add(item)
    end

    return items
end

function Cleany:Connect(Connection, callback)

    assert(self._cleaning ~= true, "cleaning in process")
    assert(typeof(Connection) == "RBXScriptSignal", `{Connection} is not a RBXScriptSignal`)

    local scriptConnection: RBXScriptConnection = Connection:Connect(callback)

    return self:Add(scriptConnection)
end

function GetCleanupDetails(obj)

    if typeof(obj) == "RBXScriptConnection" then
        return "Disconnect"
    end

    if type(obj) == "thread" then
        return THREAD_MARKER
    end

    if type(obj) == "function" then
        return FN_MARKER
    end

    if typeof(obj) == "Instance" then
        return "Destroy"
    end

    if typeof(obj) == "table" then
        if type(obj.Destroy) == "function" then
            return "Destroy"
        elseif type(obj.Disconnect) == "function" then
            return "Disconnect"
        end
    end

    error("cannot get a function", 2)

end

function Cleany:__cleanupObject(object, method)
    if method == FN_MARKER then
        object()
    elseif method == THREAD_MARKER then
        coroutine.close(object)
    else
        object[method](object)
    end
end

function Cleany:Clean()

    assert(self._cleaning ~= true, "already cleaning")

    if self then
        self._cleaning = true

        for _, data in pairs(self._objects) do
            self:__cleanupObject(data.object, data.Type)
        end

        table.clear(self._objects)
        self._cleaning = false
        return true
    end
end

return Cleany