require "open_weather";
require "serial_api";

local function ready()
    if owe_net.status() == nil then
        return true
    end
    sapi.send_error()
    return false
end

function scmd.WHW()
    if owe_p.has_weather then
        sapi.send_ok()
    else
        sapi.send_error()
    end
end

function scmd.WST()
    local status = owe_net.status()
    if status == nil then
        sapi.send_ok()
    else
        sapi.send(status)
    end
end

-- formatted weather text for 3 days intenden to be used with LEAClock
function scmd.WFF()
    if not ready() then
        return
    end
    sapi.send(owe_p.forecast_text)
end

-- forecast codes
function scmd.WFC()
    if not ready() then
        return
    end
    local today = owe_p.forecast[1]
    local codes_str = ""
    for i = 1, today.codes_size do
        if i > 1 then
            codes_str = codes_str .. ","
        end
        codes_str = codes_str .. today.codes[i]
    end
    sapi.send(codes_str)
end

-- current weather
-- Possible params:
-- - temp - current temp
-- - icons - current icons
function scmd.WCW(param)
    if ready() == false then
        return
    end
    sapi.send(owe_p.current[param])
end



