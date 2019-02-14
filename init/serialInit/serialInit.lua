require "credentials"
require "serialAPI"
require "serialAPIClock"
require "serialAPIOpenWeather"

--ntpc.syncPeriodSec = 36000 -- 10 hours 
--owe.syncPeriodSec = 1800 -- 30 minutes
ntpc.syncPeriodSec = 600
owe_net.syncPeriodSec = 600

local syncToleranceSec = 60

local function getNtpcStat() 
  local ntpcStat = ''
  if ntpc.lastSyncSec == -1 then
    ntpcStat = "TIME ERROR"  
  elseif ntpc.lastSyncSec - syncToleranceSec > ntpc.syncPeriodSec then 
    ntpcStat = "TIME OLD"
  end
  return ntpcStat;
end

local function getOweStat() 
  local oweStat = ''
  if owe_net.lastSyncSec == -1 then
    oweStat = "WEATHER ERROR"  
  elseif owe_net.lastSyncSec - syncToleranceSec > owe_net.syncPeriodSec then
    oweStat = "WEATHER OLD"
  end
  return oweStat;
end

-- return short status for all modules.
function scmd.GSS()
  local ntpcStat = getNtpcStat()
  local oweStat = getOweStat()
  
  local status
  if ntpcStat ~= '' or oweStat ~= '' then
    status = string.format("RAM:%u %s %s", node.heap(), ntpcStat, oweStat)
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
owe_net.start()
