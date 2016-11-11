require "ntp"

-- Simple clock with precision of one second. It's bing synchronized with NTP server.
ntpc = {
	current = 0, -- Curent UTC time in seconds since 1.1.1970.
	lastSyncSec = -1, -- Seconds since last sync with NTP server
	syncPeriodSec = 86400, -- period in seconds to sync with NTP server. 86400 = 24 hours
	timerId = 1
}

local ntp

local function onNtpResponse(ts)
	ntpc.current = ts
	ntpc.lastSyncSec = 0
end

local function onTimer()
	ntpc.current = ntpc.current + 1
	if ntpc.lastSyncSec >= 0 then
		ntpc.lastSyncSec = ntpc.lastSyncSec + 1
	end
	
	if ntpc.lastSyncSec == ntpc.syncPeriodSec then
		wlan.execute(function() ntpc.lastSyncSec = -1 ntp:requestTime() end)
	end
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

	ntp:registerResponseCallback(onNtpResponse)
	wlan.execute(function() ntp:requestTime() end)
	tmr.alarm(ntpc.timerId, 1000, tmr.ALARM_AUTO, onTimer)
end

local mt = {}

mt.__tostring = function(ntpc)
	return string.format("NTPC->%d,%s", ntpc.lastSyncSec, tostring(ntp))
end

setmetatable(ntpc, mt)
