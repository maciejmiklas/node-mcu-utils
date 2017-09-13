require "ntp"
require "wlan";

-- Simple clock with precision of one second. It's bing synchronized with NTP server.
ntpc = {
	current = 0, -- Curent UTC time in seconds since 1.1.1970.
	syncPeriodSec = 86400, -- period in seconds to sync with NTP server. 86400 = 24 hours
	timerId = 1
}

local ntp
local lastReqSec = 0 -- Seconds since last sync request to NTP server
local stats = {
	ntpReqTime = -1,
	ntpRespTime = -1
}

local function onNtpResponse(ts)
	ntpc.current = ts
	stats.ntpRespTime = tmr.time()
end

local function execNtpRequest()
	stats.ntpReqTime = tmr.time()
	lastReqSec = 0
	ntp:requestTime()
end

-- timer must run every second, because we use it to drive clock.
local function onTimer()
	ntpc.current = ntpc.current + 1
	lastReqSec = lastReqSec + 1
	
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

	ntp:registerResponseCallback(onNtpResponse)
	wlan.execute(execNtpRequest)
	
	-- timer must run every second, because we use it to drive clock.
	tmr.alarm(ntpc.timerId, 1000, tmr.ALARM_AUTO, onTimer)
end

function ntpc.lastSyncSec() 
	local lastSyncSec = -1
	if stats.ntpRespTime ~= -1 then
		lastSyncSec = tmr.time() - stats.ntpRespTime
	end
	return lastSyncSec;
end

--[[
local mt = {}
mt.__tostring = function(ntpc)
	return string.format("NTPC->%d,N_RQ:%d,N_RS:%d,%s", ntpc.lastSyncSec(), stats.ntpReqTime, stats.ntpRespTime, tostring(ntp))
end
setmetatable(ntpc, mt)
--]]