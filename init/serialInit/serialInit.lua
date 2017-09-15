require "credentials"
require "serialAPI"
require "serialAPIClock"
require "serialAPIYahooWeather"

ntpc.syncPeriodSec = 7200 -- 2 hours
yaw.syncPeriodSec = 720 -- 15 minutes

local gtsCall = 0;

-- return status for all modules.
--function scmd.GST()
--	gtsCall = gtsCall + 1;
--	uart.write(0, string.format("NOW:%u;CNT:%u;RAM:%u;%s;%s;%s", tmr.time(), gtsCall, node.heap(), 
--	 tostring(wlan), tostring(ntpc), tostring(yaw)))
--end

-- return short status for all modules.
function scmd.GSS()
	gtsCall = gtsCall + 1;
   
	uart.write(0, string.format("CNT:%u;RAM:%u;C:%d;Y:%d;YE:%d", gtsCall, node.heap(), ntpc.lastSyncSec(), 
	 yaw.lastSyncSec(), yaw.respErrCnt()))
end

-- network connect
wlan.setup(cred.ssid, cred.password)

-- start serial API by enabling gpio and uart
sapi.start()

-- start NTP synchronization
ntpc.start("pool.ntp.org")

-- start yahoo weather with serial API
yaw.start()
