collectgarbage() print("RAM init", node.heap())
require "credentials"
require "wlan"
require "ntp"
require "dateformatEurope";

collectgarbage() print("RAM after require", node.heap())

wlan.setup(cred.ssid, cred.password)

ntp = NtpFactory:fromDefaultServer()

local function printTime(ts) 
	collectgarbage() print("RAM before printTime", node.heap())
	
	df.setEuropeTime(ts, 3600)
	
	print("NTP Local Time:", string.format("%04u-%02u-%02u %02u:%02u:%02d", 
		df.year, df.month, df.day, df.hour, df.min, df.sec))
	print("Summer Time:", df.summerTime)
	print("Day of Week:", df.dayOfWeek)
	
	collectgarbage() print("RAM after printTime", node.heap())
end

ntp:registerResponseCallback(printTime)

wlan.execute(function() ntp:requestTime() end)

tmr.alarm(2, 5000, tmr.ALARM_AUTO, function() print("NTP Status:", tostring(ntp), tostring(wlan)) end) 

collectgarbage() print("RAM callbacks", node.heap())
 
