require "credentials"
require "serialAPI"
require "serialAPIClock"
require "serialAPIYahooWeather"

ntpc.syncPeriodSec = 36000 -- 10 hours
yaw.syncPeriodSec = 1800 -- 30 minutes

local syncMarginSec = 120

-- return status for all modules.
--[[
function scmd.GST()
	gtsCall = gtsCall + 1;
	uart.write(0, string.format("NOW:%u;CNT:%u;RAM:%u;%s;%s;%s", tmr.time(), gtsCall, node.heap(),
	 tostring(wlan), tostring(ntpc), tostring(yaw)))
end
--]]

local function getNtpcStat() 
  local ntpcStat = ''
  if ntpc.lastSyncSec() == -1 then
    ntpcStat = "TIME ERROR"  
  elseif ntpc.lastSyncSec() - syncMarginSec > ntpc.syncPeriodSec then 
    ntpcStat = "TIME OLD"
  end
  return ntpcStat;
end

local function getYawStat() 
  local yawStat = ''
  if yaw.lastSyncSec() == -1 then
    yawStat = "WEATHER ERROR"  
  elseif yaw.lastSyncSec() - syncMarginSec > yaw.syncPeriodSec then 
    yawStat = "WEATHER OLD"
  end
  return yawStat;
end

-- return short status for all modules.
function scmd.GSS()

  local ntpcStat = getNtpcStat()
  local yawStat = getYawStat()
  
  local status
  if ntpcStat ~= '' or yawStat ~= '' then
    status = string.format("RAM:%u %s %s", node.heap(), ntpcStat, yawStat)
  else
    status = "1"
  end

  uart.write(0, status)
end

-- network connect
wlan.setup(cred.ssid, cred.password)

-- start serial API by enabling gpio and uart
sapi.start()

-- start NTP synchronization
ntpc.start("pool.ntp.org")

-- start yahoo weather with serial API
yaw.start()
