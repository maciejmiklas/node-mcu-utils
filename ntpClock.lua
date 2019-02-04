require "ntp"
require "wlan";

-- Simple clock with precision of one second. It's bing synchronized with NTP server.
ntpc = {
	current = 0, -- Curent UTC time in seconds since 1.1.1970.
	syncPeriodSec = 86400, -- period in seconds to sync with NTP server. 86400 = 24 hours
	lastSyncSec = -1 -- Seconds since last response from NTP server.
}

local ntp
local lastReqSec = 0 -- Seconds since last sync request to NTP server

local function onNtpResponse(ts)
	ntpc.current = ts
	ntpc.lastSyncSec = 0
end

local function execNtpRequest()
	lastReqSec = 0
	ntp:requestTime()
end

-- timer must run every second, because we use it to drive clock.
local function onTimer()
	ntpc.current = ntpc.current + 1
	lastReqSec = lastReqSec + 1
  ntpc.lastSyncSec = ntpc.lastSyncSec + 1
	
	if lastReqSec == ntpc.syncPeriodSec then
		wlan.execute(execNtpRequest)
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

	ntp:onResponse(onNtpResponse)
	wlan.execute(execNtpRequest)
	
	-- timer must run every second, because we use it to drive clock.
	local timer = tmr.create()
	timer:register(1000, tmr.ALARM_AUTO, onTimer)
	timer:start()
end