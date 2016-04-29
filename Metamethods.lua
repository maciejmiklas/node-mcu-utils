Window = {}
Window.prototype = {x=0, y=0, width = 100, height = 100}
Window.mt = {}
Window.mt.__index = function (table,key)
    return Window.prototype(key)
end

function Window.new (o)
    setmetatable(o, Window.mt)
end

w = Window.new{x=1, y = 20}
print(w.x, w.width)