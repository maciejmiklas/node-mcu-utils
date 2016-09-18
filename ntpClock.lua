require "ntp"

-- Simple clock with precision of one second. It's bing synchronized with NTP server.
nc = {
	current = 0, -- Curent UTC time in seconds since 1.1.1970. 
	lastSync = -1, -- Seconds since last sync with NTP server
	syncPeriod = 86400, -- 86400 - 24 hours
	debug = false
}

local pr = {
	ntp = nil
}

local function onNtpResponse(ts)
	nc.current = ts
	nc.lastSync = 0
end

local function onTimerEvent()
	nc.current = nc.current + 1
	nc.lastSync = nc.lastSync + 1
	
	if nc.lastSync == nc.syncPeriod then
		wlan.execute(function() pr.ntp:requestTime() end)
	end	
end

-- Starts periodical time syncronization with NTC server. It also executes first syncronization
-- without delay.
--
-- ntpServer - URL of NTP server or nil to use default one
-- syncPeriod - period in seconds to sync with NTP server. 24 hours if nil.
-- timerId - timer id for tmr module. 1 if nil.
function nc.start(ntpServer, syncPeriod, timerId)
	assert(pr.ntp == nil)
	
	if timerId == nil then timerId = 1 end
	if syncPeriod ~= nil then nc.syncPeriod = syncPeriod end

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