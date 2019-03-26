-- http://api.openweathermap.org/data/2.5/forecast?id=3081368&appid=3afb55b99aafbe3310545e4ced598754&units=metric
require "wlan";
require "open_weather_parser"
require "log"
require "scheduler"

owe_net = {
    url = "http://api.openweathermap.org/data/2.5/forecast?id=3081368&appid=3afb55b99aafbe3310545e4ced598754&units=metric",
    sync_period_sec = 60, -- sync weather every 20 minutes
    sync_on_error_pause_sec = 20,
    weather = nil,
    response_callback = nil,
    last_sync_sec = -1, -- Seconds since last response from weather server.
    sync_tolerance_sec = 10
}
local con
local jlp = JsonListParser.new()
jlp:register_element_ready(owe_p.on_next_document)

function owe_net.status()
    local status = nil
    if owe_net.last_sync_sec == -1 or owe_p.has_weather == false or owe_p.forecast_text == nil then
        status = "WEATHER ERROR"
    elseif scheduler.uptime_sec() - owe_net.last_sync_sec > owe_net.sync_period_sec + owe_net.sync_tolerance_sec then
        status = "WEATHER OLD"
    end
    return status;
end

local function close()
    if con ~= nil then pcall(function() con:close() end) end
end

local function on_data(status_code, data)
    if status_code < 0 then
        if log.is_error then log.error("OWE response: ", statusCode, " -> ", data) end
        close()
        return
    end
    if log.is_debug then log.debug("OWE frame: ", (string.len(data) / 1000)) end
    local status, response = pcall(function() return jlp:on_next_chunk(data) end)
    if status then
        if not response then
            if log.is_debug then log.debug("OWE request parsed") end
            close()
        end
    else
        if log.is_error then log.error("OWE callback: ", response, "->", data) end
        close()
    end
end

local function on_connect()
    if log.is_debug then log.debug("OWE connected") end
    jlp:reset()
    owe_p.on_data_start()
end

local function request_weather()
    if log.is_info then log.info("OWE Request werather") end
    if con == nil then
        headers = {
            Connection = "close"
        }
        con = http.createConnection(owe_net.url, http.GET, { headers = headers, async = true })
        con:on("data", on_data)
        con:on("connect", on_connect)
        con:on("complete", function() owe_net.last_sync_sec = scheduler.uptime_sec() end)
    end
    con:close()
    con:request()
end

local function on_scheduler()
    wlan.execute(request_weather)
end

function owe_net.start()
    scheduler.register(on_scheduler, "weather", owe_net.sync_period_sec, owe_net.sync_on_error_pause_sec)
end