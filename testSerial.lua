require "credentials"
require "serialAPI"
require "serialAPIClock"
require "serialAPIYahooWeather"
require "yahooWeather"

ntpc.syncPeriodSec = 900 -- 15 min
yaw.syncPeriodSec = 1020 -- 17 min
sapi.baud = 115200

-- setup wlan required by NTP clokc
wlan.setup(cred.ssid, cred.password)

-- start serial API by enabling gpio and uart
sapi.start()

-- start NTP synchronization
ntpc.start("pool.ntp.org")

-- start yahoo weather with serial API
yaw.start()