require "scheduler"

blink = {
    led_pin = 2 -- D2
}
local status = 0

local function on_scheduler()
    if status == 0 then
        status = 1
    else
        status = 0
    end
    gpio.write(blink.led_pin, status)
end

function blink.start()
    gpio.config({ gpio = blink.led_pin, dir = gpio.OUT })
    scheduler.register(on_scheduler, "blink", 1, 1)
end