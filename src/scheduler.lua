require "log"

scheduler = {}
local callbacks = {}
local time_sec = 0
local tmrObj

function scheduler.register(callback, name, frequency_sec, retry_sec)
    if log.is_info then log.info("SCH register: ", name, " for ", frequency_sec, "/", retry_sec, " sec") end

    local entry = {}
    entry.callback = callback
    entry.name = name
    entry.frequency_sec = frequency_sec
    entry.retry_sec = retry_sec
    entry.executed_sec = -1
    table.insert(callbacks, entry)
end

function scheduler.uptime_sec()
    return time_sec
end

local function on_timer()
    time_sec = time_sec + 1
    for _, entry in pairs(callbacks) do
        if entry.executed_sec == -1 or (time_sec - entry.executed_sec >= entry.frequency_sec) then
            local status, err = pcall(entry.callback)
            if status then
                entry.executed_sec = time_sec
            else
                if log.is_error then log.error("SCH:", entry.name, "->", err) end
                entry.executed_sec = time_sec - entry.retry_sec
            end
        end
    end
end

function scheduler.start()
    tmrObj = tmr.create()
    tmrObj:register(2000, tmr.ALARM_AUTO, on_timer)
    tmrObj:start()
end