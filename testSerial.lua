require "credentials"
require "serialAPI"
require "serialAPIClock"
require "serialAPIYahooWeather"
require "yahooWeather"

wlan.debug = true
sapi.debug = true
sapiClock.debug = true
ntpc.debug = true
yaw.debug = true
yaw.trace = false

ntpc.syncPeriodSec = 1800
sapi.baud = 115200

-- setup wlan required by NTP clokc
wlan.setup(cred.ssid, cred.password)

local function onWlanReady()
	-- start serial API by enabling gpio and uart
	sapi.start()
	
	-- start NTP synchronization
	ntpc.start("pool.ntp.org")
	
	-- start yahoo weather with serial API
	yaw.start()
end

-- start all after obtaining wlan connection
wlan.execute(onWlanReady)


