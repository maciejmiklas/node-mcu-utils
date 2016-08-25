require "ntp"

-- Simple clock with precision of one second. It's bing synchronized with NTP server.
nc = {
	current = 0, -- Curent UTC time in seconds since 1.1.1970. 
	lastSyncSec = -1, -- Seconds since last sync with NTP server
	syncPeriodSec = 86400, -- 86400 - 24 hours
	debug = false
}

local pr = {
	ntp = nil
}

local function onNtpResponse(ts)
	nc.current = ts
	nc.lastSyncSev = 0
end

local function onTimerEvent()
	nc.current = nc.current + 1
	nc.lastSyncSec = nc.lastSyncSec + 1
	
	if nc.lastSyncSec == nc.syncPeriodSec then
		wlan.execute(function() pr.ntp:requestTime() end)
	end	
end

-- Starts periodical time syncronization with NTC server. It also executes first syncronization
-- without delay.
--
-- ntpServer - URL of NTP server or nil to use default one
-- syncPeriodSec - period in seconds to sync with NTP server. 24 hours if nil.
-- timerId - timer id for tmr module. 1 if nil.
function nc.start(ntpServer, syncPeriodSec, timerId)
	assert(pr.ntp == nil)
	
	if timerId == nil then timerId = 1 end
	if syncPeriodSec ~= nil then nc.syncPeriodSec = syncPeriodSec end

	if ntpServer ~= nil then
		pr.ntp = NtpFactory:fromServer(ntpServer)
	else
		pr.ntp = NtpFactory:fromDefaultServer()
	end

	if nc.debug then pr.ntp:withDebug() end
	pr.ntp:registerResponseCallback(onNtpResponse)
	pr.ntp:requestTime()
	tmr.alarm(timerId, 1000, tmr.ALARM_AUTO, onTimerEvent)
end