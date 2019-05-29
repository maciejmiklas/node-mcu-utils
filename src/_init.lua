require "date_format_europe";
require "serial_api_clock"
require "serial_api_open_weather"
require "blink"
require "scheduler"
require "credentials"

function scmd.GFR()
    collectgarbage()
    sapi.send("RAM: " .. tostring(node.heap() / 1000))
end

local gtc = {
    last_weather_sync_sec = -1,
    ntpc_stat = nil,
    owe_stat = nil,
    text = "Initializing.....       ",
    update_count = 0,
    last_gtc_call = -1,
    print_always_ram = true
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
    local owe_stat = owe.status()
    local status = {}
    if ntpc_stat == nil and owe_stat == nil then
        status = "OK"
    else
        if ntpc_stat ~= nil then
            table.insert(text, " ")
        end
        if owe_stat ~= nil then
            table.insert(text, owe_stat)
        end
        table.insert(text, "; RAM:")
        table.insert(text, node.heap() / 1000)
        table.insert(text, "kb")
    end
    sapi.send(table.concat(status))
end

-- return 1 if the text has been changed since last call, otherwise 0
function scmd.GTC()
    local changed
    if gtc.update_count == 0 then
        changed = '1'

    elseif gtc.last_gtc_call == gtc.update_count then
        changed = '0'
    else
        changed = '1'
        gtc.last_gtc_call = gtc.update_count
    end
    sapi.send(changed)
end

-- scrolling text for arduino
function scmd.GTX()
    sapi.send(gtc.text)
end

local function generate_weather_text(ntpc_stat, owe_stat)
    local text = {}
    if ntpc_stat == nil and owe_stat == nil then
        table.insert(text, owe.forecast_text())
        table.insert(text, " >> RAM:")
        table.insert(text, node.heap() / 1000)
        table.insert(text, "kb")
        table.insert(text, "          ")
    else

        local ft = owe.forecast_text()
        if ft ~= nil and ft:len() > 0 then
            table.insert(text, ft)
            table.insert(text, " >> ")
        end

        if owe_stat ~= nil then
            table.insert(text, owe_stat)
        end
        if ntpc_stat ~= nil then
            if owe_stat ~= nil then
                table.insert(text, ", ")
            end
            table.insert(text, " ")
            table.insert(text, ntpc_stat)
        end
        if print_always_ram then
            collectgarbage()
            table.insert(text, " >> RAM:")
            table.insert(text, node.heap() / 1000)
            table.insert(text, "kb")
        end
        table.insert(text, "          ")
    end
    return table.concat(text)
end

local function update_weather()
    local ntpc_stat = ntpc.status()
    local owe_stat = owe.status()
    local last_weather_sync_sec = owe.last_sync_sec

    if gtc.last_weather_sync_sec == last_weather_sync_sec and gtc.ntpc_stat == ntpc_stat and gtc.owe_stat == owe_stat then
        return
    end
    gtc.last_weather_sync_sec = last_weather_sync_sec
    gtc.ntpc_stat = ntpc_stat
    gtc.owe_stat = owe_stat
    local new_text = generate_weather_text(ntpc_stat, owe_stat)
    if (new_text == gtc.text) then
        if log.is_info then
            log.info("INT Weather did not change")
        end
    else
        gtc.update_count = gtc.update_count + 1
        gtc.text = new_text
        if log.is_info then
            log.info("INT new weather:", gtc.text)
        end
    end
end

local function print_stuff()
    print("############")
    scmd.GFR()
    scmd.GTX()
    scmd.CFD()
    scmd.WCW("temp")
    print("############")
end

scheduler.register(print_stuff, "print_stuff", 5, 5)
owe.sync_period_sec = 60
sapi.uart_id = 0


owe.register_response_callback(update_weather)
wlan.setup(cred.ssid, cred.password)
sapi.start()
ntpc.start("pool.ntp.org")
owe.start()
blink.start()
scheduler.start()