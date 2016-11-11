require "credentials"
require "serialAPI"
require "serialAPIClock"
require "serialAPIYahooWeather"
require "yahooWeather"

ntpc.syncPeriodSec = 120
yaw.syncPeriodSec = 180
--ntpc.syncPeriodSec = 900 -- 15 min
--yaw.syncPeriodSec = 1020 -- 17 min

local gtsCall = 0;

-- return status for all modules.
function scmd.GST()
	gtsCall = gtsCall + 1;
	uart.write(0, string.format("NOW:%u;CNT:%u;RAM:%u;%s;%s;%s", tmr.time(), gtsCall, node.heap(), tostring(wlan), tostring(ntpc), tostring(yaw)))
end

-- setup wlan required by NTP clokc
wlan.setup(cred.ssid, cred.password)

-- start serial API by enabling gpio and uart
sapi.start()

-- start NTP synchronization
ntpc.start("pool.ntp.org")

-- start yahoo weather with serial API
yaw.start()
