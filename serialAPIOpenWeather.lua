require "openWeather";
require "serialAPI";

local function ready()
    if owe_p.hasWeather then
        return true
    end
    sapi.sendError()
    return false
end

function scmd.WST()
    if owe_p.hasWeather then
        sapi.sendOK()
    else
        sapi.sendError()
    end
end

-- formatted weather text for 3 days intenden to be used with LEAClock
function scmd.WFF()
    if not ready() then
        return
    end
    uart.write(0, owe_p.forecastText .. '\n')
end

function scmd.WFC()
    if not ready() then
        return
    end
    local today = owe_p.forecast[1]
    local codesStr = ""
    for i = 1, today.codesSize do
        if i > 1 then codesStr = codesStr .. "," end
        codesStr = codesStr .. today.codes[i]
    end
    uart.write(0, codesStr .. '\n')
end

-- current weather
-- Possible params:
-- - temp - current temp
-- - icons - current icons
function scmd.WCW(param)
    if ready() == false then
        return
    end
    uart.write(0, owe_p.current[param] .. '\n')
end



