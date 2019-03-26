require "date_format_europe";
require "credentials"
require "serial_api_clock"
require "serial_api_open_weather"
require "blink"
require "scheduler"

function scmd.GFR()
    collectgarbage()
    uart.write(sapi.urat_id, "RAM: ")
    uart.write(sapi.urat_id, tostring(node.heap() / 1000))
    uart.write(sapi.urat_id, '\n')
end

local change = {
    last_weather_sync_sec = -1,
    ntpc_stat = nil,
    owe_stat = nil,
    text = "",
    update_count = 0,
    last_gtc_call = -1
}

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
    uart.write(sapi.urat_id, status)
end

-- return 1 if the text has been changed since last call, otherwise 0
function scmd.GTC()
    local changed = "1"
    if change.last_gtc_call == change.update_count then
        changed = "0"
    end
    change.last_gtc_call = change.update_count
    uart.write(sapi.urat_id, changed)
end

-- scrolling text for arduino
function scmd.GTX()
    uart.write(sapi.urat_id, change.text)
end

local function generate_weather_text(ntpc_stat, owe_stat)
    local text = "Initializing.....       "
    if ntpc_stat == nil and owe_stat == nil then
        text = owe_p.forecast_text
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
    end
    text = text .. " >> RAM:" .. (node.heap() / 1000) .. "kb"
    text = text .. "          "
    return text
end

local function update_wehater_text()
    local ntpc_stat = ntpc.status()
    local owe_stat = owe_net.status()
    local last_weather_sync_sec = owe_net.last_sync_sec

    if change.last_weather_sync_sec == last_weather_sync_sec and change.ntpc_stat == ntpc_stat and change.owe_stat == owe_stat then
        return
    end
    if log.is_debug then log.debug("Update weather text") end

    change.last_weather_sync_sec = last_weather_sync_sec
    change.ntpc_stat = ntpc_stat
    change.owe_stat = owe_stat
    change.text = generate_weather_text(ntpc_stat, owe_stat)
    change.update_count = change.update_count + 1
end

local function print_stuff()
    scmd.GFR()
    scmd.WFF()
    scmd.CFD()
end

scheduler.register(update_wehater_text, "update_wehater_text", 1, 1)
scheduler.register(print_stuff, "print_stuff", 60, 60)


wlan.setup(cred.ssid, cred.password)
sapi.start()
ntpc.start("pool.ntp.org")
owe_net.start()
blink.start()
scheduler.start()