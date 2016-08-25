require "credentials"
require "serialAPI"
require "serialAPIClock"

wlan.debug = true
sapi.debug = true
sapiClock.debug = true

nc.syncPeriodSec = 1800

-- setup wlan required by NTP clokc
wlan.setup(cred.ssid, cred.password)

-- init serial API by enabling gpio and uart
sapi.setup()

-- start NTP clock
sapiClock.setup()