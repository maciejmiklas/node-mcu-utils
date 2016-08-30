require "ntp"

-- Simple clock with precision of one second. It's bing synchronized with NTP server.
ntpc = {
	current = 0, -- Curent UTC time in seconds since 1.1.1970. 
	lastSyncSec = -1, -- Seconds since last sync with NTP server
	syncPeriodSec = 86400, -- period in seconds to sync with NTP server. 86400 = 24 hours
	debug = false,
	timerId = 1
}

local pr = {
	ntp = nil
}

local function onNtpResponse(ts)
	ntpc.current = ts
	ntpc.lastSyncSev = 0
end

local function onTimerEvent()
	ntpc.current = ntpc.current + 1
	ntpc.lastSyncSec = ntpc.lastSyncSec + 1
	
	if ntpc.lastSyncSec == ntpc.syncPeriodSec then
		wlan.execute(function() pr.ntp:requestTime() end)
	end	
end

-- Starts periodical time syncronization with NTC server. It also executes first syncronization
-- without delay.
--
-- ntpServer - URL of NTP server or nil to use default one
function ntpc.start(ntpServer)
	assert(pr.ntp == nil)

	if ntpServer ~= nil then
		pr.ntp = NtpFactory:fromServer(ntpServer)
	else
		pr.ntp = NtpFactory:fromDefaultServer()
	end

	if ntpc.debug then pr.ntp:withDebug() end
	pr.ntp:registerResponseCallback(onNtpResponse)
	pr.ntp:requestTime()
	tmr.alarm(ntpc.timerId, 1000, tmr.ALARM_AUTO, onTimerEvent)
end