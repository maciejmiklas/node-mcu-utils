require "log"

scheduler = {}
local callbacks = {}
local timeSec = 0
local tmrObj

function scheduler.register(callback, name, frequencySec, retrySec)
    if log.isInfo then log.info("Register timer: " .. name .. " for " .. frequencySec.."/"..retrySec.." sec") end

    local entry = {}
    entry.callback = callback
    entry.name = name
    entry.frequencySec = frequencySec
    entry.retrySec = retrySec
    entry.executedSec = -1
    table.insert(callbacks, entry)
end

function scheduler.uptimeSec()
    return timeSec
end

local function onTimer()
    timeSec = timeSec + 1
    for _, entry in pairs(callbacks) do
        if entry.executedSec == -1 or (timeSec - entry.executedSec >= entry.frequencySec) then
            --if log.isInfo then log.info("Timer on: " .. entry.name) end
            local status, err = pcall(entry.callback)
            if status then
                entry.executedSec = timeSec
            else
                log.error("Timer:" .. entry.name .. "->" .. err)
                entry.executedSec = timeSec - entry.retrySec
            end
        end
    end
end

function scheduler.start()
    tmrObj = tmr.create()
    tmrObj:register(1000, tmr.ALARM_AUTO, onTimer)
    tmrObj:start()
end