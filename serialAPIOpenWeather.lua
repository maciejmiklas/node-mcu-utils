require "openWeather";

local function ready()
    if owe_p.hasWeather then
        return true
    end
    uart.write(0, "ER\n")
    return false
end

local function uartError()
    uart.write(0, "ER\n")
end

function scmd.WST()
    if owe_p.hasWeather then
        uart.write(0, "OK\n")
    else
        uartError()
    end
end

-- current weather
-- Possible params:
-- - temp - current temp
-- - icons - current icons
function scmd.WCW(param)
    if ready() == false then
        return
    end
    if param == "temp" then
        uart.write(0, owe_p.forecast[1].temp .. '\n')
    elseif param == "icons" then
        uartError()
    else
        uartError()
    end
end

-- formatted weather text for 3 days intenden to be used with LEAClock
function scmd.WFF()
    if ready() == false then
        return
    end
    uart.write(0, owe_p.forecastText .. '\n')
end

