require "date_format_europe";
require "credentials"
require "serial_api_clock"
require "serial_api_open_weather"
require "blink"
require "scheduler"

function scmd.GFR()
    collectgarbage()
    sapi.send("RAM: " .. tostring(node.heap() / 1000))
end

local gtc_buf = {
    last_weather_sync_sec = -1,
    ntpc_stat = nil,
    owe_stat = nil,
    text =  "Initializing.....       ",
    update_count = 0,
    last_gtc_call = -1
}

-- set debug level
function scmd.GDL(level)
    if level == '0' then
        log.setup(false, false, false, false)

    elseif level == '1' then
        log.setup(false, false, false, true)

    elseif level == '2' then
        log.setup(false, false, true, true)

    elseif level == '3' then
        log.setup(false, true, true, true)

    elseif level == '4' then
        log.setup(true, true, true, true)
    end
end

-- return short status for all modules.
function scmd.GSS()
    local ntpc_stat = ntpc.status()
    local owe_stat = owe_net.status()
    local status = ""
    if ntpc_stat == nil and owe_stat == nil then
        status = "OK"
    else
        if ntpc_stat ~= nil then
            status = status .. ntpc_stat .. " "
        end
        if owe_stat ~= nil then
            status = status .. owe_stat
        end
        status = status .. "; RAM:" .. (node.heap() / 1000) .. "kb"
    end
    sapi.send(status)
end

-- return 1 if the text has been changed since last call, otherwise 0
function scmd.GTC()
    local changed
    if gtc_buf.last_gtc_call == gtc_buf.update_count then
        changed = '0'
    else
        changed = '1'
        gtc_buf.last_gtc_call = gtc_buf.update_count
    end
    sapi.send(changed)
end

-- scrolling text for arduino
function scmd.GTX()
    sapi.send(gtc_buf.text)
end

local function generate_weather_text(ntpc_stat, owe_stat)
    local text = ""
    if ntpc_stat == nil and owe_stat == nil then
        text = owe_p.forecast_text.."          "
    else
        collectgarbage()
        if owe_p.forecast_text ~= nil and owe_p.forecast_text:len() > 0 then
            text = owe_p.forecast_text .. " >> "
        end

        if owe_stat ~= nil then
            text = text .. owe_stat
        end
        if ntpc_stat ~= nil then
            text = " " .. text .. " " .. ntpc_stat
        end
        text = text .. " >> RAM:" .. (node.heap() / 1000) .. "kb"
        text = text .. "          "
    end
    return text
end

-- TODO update as event on weather change, timer can also stay in case of errors
local function update_weather_text()
    local ntpc_stat = ntpc.status()
    local owe_stat = owe_net.status()
    local last_weather_sync_sec = owe_net.last_sync_sec

    if gtc_buf.last_weather_sync_sec == last_weather_sync_sec and gtc_buf.ntpc_stat == ntpc_stat and gtc_buf.owe_stat == owe_stat then
        return
    end
    if log.is_debug then
        log.debug("Update weather text")
    end

    gtc_buf.last_weather_sync_sec = last_weather_sync_sec
    gtc_buf.ntpc_stat = ntpc_stat
    gtc_buf.owe_stat = owe_stat
    gtc_buf.text = generate_weather_text(ntpc_stat, owe_stat)
    gtc_buf.update_count = gtc_buf.update_count + 1
end

local function print_stuff()
    scmd.GFR()
    scmd.WFF()
    scmd.CFD()
    scmd.WCW("temp")
end

scheduler.register(update_weather_text, "update_wehater_text", 1, 1)
--scheduler.register(print_stuff, "print_stuff", 60, 60)

wlan.setup(cred.ssid, cred.password)
sapi.start()
ntpc.start("pool.ntp.org")
owe_net.start()
blink.start()
scheduler.start()