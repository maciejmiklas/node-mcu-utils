-- http://api.openweathermap.org/data/2.5/forecast?id=3081368&appid=3afb55b99aafbe3310545e4ced598754&units=metric
require "wlan";
require "open_weather_parser"
require "log"
require "scheduler"

owe = {
    appid = "XYZ",
    url = "http://api.openweathermap.org/data/2.5/forecast?id=3081368&units=metric&appid=",
    sync_period_sec = 1200, -- sync weather every 20 minutes
    sync_on_error_pause_sec = 180,
    last_sync_sec = -1, -- Seconds since last response from weather server.
    sync_tolerance_sec = 120,
    utc_offset = 3600,
    response_callback = nil
}
local con
local jlp = JsonListParser.new()

function owe.forecast(param)
    return owe_p.forecast[param]
end

function owe.forecast_text()
    return owe_p.forecast_text
end

function owe.current(param)
    return owe_p.current[param]
end

function owe.has_weather()
    return owe_p.has_weather
end

function owe.register_response_callback(callback)
    owe.response_callback = callback
end

function owe.status()
    local status = nil
    if owe.last_sync_sec == -1 or owe_p.has_weather == false or owe_p.has_weather == nil then
        status = "WEATHER ERROR"
    elseif scheduler.uptime_sec() - owe.last_sync_sec > owe.sync_period_sec + owe.sync_tolerance_sec then
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
            owe.last_sync_sec = scheduler.uptime_sec()
            close()
            if owe.response_callback ~= nil then
                owe.response_callback()
            end
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
    if log.is_info then log.info("OWE Request weather") end
    if con == nil then
        headers = {
            Connection = "close"
        }
        con = http.createConnection(owe.url..owe.appid, http.GET, { headers = headers, async = true })
        con:on("data", on_data)
        con:on("connect", on_connect)
    end
    con:close() -- close previous connection
    con:request()
end

local function on_scheduler()
    wlan.execute(request_weather)
end

function owe.start()
    jlp:register_element_ready(owe_p.on_next_document)
    owe_p.utc_offset = owe.utc_offset
    scheduler.register(on_scheduler, "weather", owe.sync_period_sec, owe.sync_on_error_pause_sec)
end