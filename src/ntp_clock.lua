require "ntp"
require "wlan";
require "scheduler"


-- Simple clock with precision of one second. It's bing synchronized with NTP server.
ntpc = {
    current = 0, -- Curent UTC time in seconds since 1.1.1970.
    sync_period_sec = 3600, -- period in seconds to sync with NTP server. 3600 = an hour
    syncPeriodRetrySec = 120,
    last_sync_sec = -1, -- Seconds since last response from NTP server.
    sync_tolerance_sec = 300,
}

local ntp, timer

function ntpc.status()
    local status = nil
    if ntpc.last_sync_sec == -1 then
        status = "TIME ERROR"
    elseif scheduler.uptime_sec() - ntpc.last_sync_sec > ntpc.sync_period_sec + ntpc.sync_tolerance_sec then
        status = "TIME OLD"
    end
    return status;
end

local function on_ntp_response(ts)
    ntpc.current = ts
    ntpc.last_sync_sec = scheduler.uptime_sec()
end

-- timer must run every second, because we use it to drive clock.
local function on_timer()
    ntpc.current = ntpc.current + 1
end

local function on_scheduler()
    wlan.execute(function()
        ntp:request_time()
    end)
end

-- Starts periodical time syncronization with NTC server. It also executes first syncronization
-- without delay.
--
-- ntpServer - URL of NTP server or nil to use default one
function ntpc.start(ntpServer)
    assert(ntp == nil)

    if ntpServer ~= nil then
        ntp = NtpFactory:from_server(ntpServer)
    else
        ntp = NtpFactory:from_default_server()
    end

    ntp:register_response_callback(on_ntp_response)

    scheduler.register(on_scheduler, "NTP", ntpc.sync_period_sec, ntpc.syncPeriodRetrySec)

    -- timer must run every second, because we use it to drive clock.
    timer = tmr.create()
    timer:register(1000, tmr.ALARM_AUTO, on_timer)
    timer:start()
end