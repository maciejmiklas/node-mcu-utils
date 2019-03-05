require "scheduler"

blink = {
    ledPin = 2 -- D2
}
local status = 0

local function onScheduler()
    if status == 0 then
        status = 1
    else
        status = 0
    end
    gpio.write(blink.ledPin, status)
end

function blink.start()
    gpio.config({ gpio = blink.ledPin, dir = gpio.OUT })
    scheduler.register(onScheduler, "blink", 1, 1)
end