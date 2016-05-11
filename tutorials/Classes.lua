Window = {}
Window.__index = Window

Window.x = 0
Window.y = 0
Window.width = 100
Window.height = 100
Window.__tostring = function(t)
    return "Window" .. " " .. t.x .. " " .. t.y .. " " .. t.width .. " " .. t.height
end


function Window:new(o)
    o = o or {} -- create table if not provided
    setmetatable(o, self) -- self is Window
    return o
end


function Window.new1(o)
    o = o or {} -- create table if not provided
    setmetatable(o, Window)
    return o
end


function Window:area()
    return self.width * self.height
end

w1 = Window:new { x = 1, y = 20, height = 20 }
print(w1)
print(w1:area())

w1a = Window.new1 { x = 1, y = 20, height = 20 }
print(w1a)
print(w1a:area())

w2 = Window:new()
print(w2)
print(w2:area())
