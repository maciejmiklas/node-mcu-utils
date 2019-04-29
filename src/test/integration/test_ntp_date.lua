collectgarbage() print("RAM init", node.heap())
require "credentials"
require "wlan"
require "ntp"
require "dateformatEurope";

collectgarbage() print("RAM after require", node.heap())

wlan.setup(cred.ssid, cred.password)

ntp = NtpFactory:from_default_server()

local function printTime(ts) 
	collectgarbage() print("RAM before printTime", node.heap())
	
	df.set_time(ts, 3600)
	
	print("NTP Local Time:", string.format("%04u-%02u-%02u %02u:%02u:%02d", 
		df.year, df.month, df.day, df.hour, df.min, df.sec))
	print("Summer Time:", df.summer_time)
	print("Day of Week:", df.day_off_week)
	
	collectgarbage() print("RAM after printTime", node.heap())
end

ntp:on_response(printTime)
wlan.execute(function() ntp:request_time() end)
collectgarbage() print("RAM callbacks", node.heap())
 
