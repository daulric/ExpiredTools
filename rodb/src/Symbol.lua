local Symbol = {}

function Symbol.assign(name)
    local new = newproxy(true)

    getmetatable(new).__tostring = function()
        return ("Assigned(%s)"):format(name)
    end

    return new
end

return Symbol