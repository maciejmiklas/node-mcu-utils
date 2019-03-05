require "ntp"
require "wlan";
require "scheduler"


-- Simple clock with precision of one second. It's bing synchronized with NTP server.
ntpc = {
    current = 0, -- Curent UTC time in seconds since 1.1.1970.
    syncPeriodSec = 86400, -- period in seconds to sync with NTP server. 86400 = 24 hours
    syncPeriodRetrySec = 30,
    lastSyncSec = -1, -- Seconds since last response from NTP server.
    syncToleranceSec = 60
}

local ntp, timer

function ntpc.status()
    local status = nil
    if ntpc.lastSyncSec == -1 then
        status = "TIME ERROR"
    elseif ntpc.lastSyncSec - ntpc.syncToleranceSec > ntpc.syncPeriodSec then
        status = "TIME OLD"
    end
    return status;
end

local function onNtpResponse(ts)
    ntpc.current = ts
    ntpc.lastSyncSec = 0
end

-- timer must run every second, because we use it to drive clock.
local function onTimer()
    ntpc.current = ntpc.current + 1
end

local function onScheduler()
    if log.isInfo then print("Request NTP") end
    wlan.execute(function() endntp:requestTime() end)
    ntpc.lastSyncSec = scheduler.uptimeSec()
end

-- Starts periodical time syncronization with NTC server. It also executes first syncronization
-- without delay.
--
-- ntpServer - URL of NTP server or nil to use default one
function ntpc.start(ntpServer)
    assert(ntp == nil)

    if ntpServer ~= nil then
        ntp = NtpFactory:fromServer(ntpServer)
    else
        ntp = NtpFactory:fromDefaultServer()
    end

    ntp:onResponse(onNtpResponse)

    scheduler.register(onScheduler, "NTP", ntpc.syncPeriodSec, ntpc.syncPeriodRetrySec)

    -- timer must run every second, because we use it to drive clock.
    timer = tmr.create()
    timer:register(1000, tmr.ALARM_AUTO, onTimer)
    timer:start()
end