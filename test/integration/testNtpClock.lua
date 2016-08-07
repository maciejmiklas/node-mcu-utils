collectgarbage() print("RAM init", node.heap())

require "dateformatEurope";
require "ntpClock";
require "wlan";

collectgarbage() print("RAM after require", node.heap())

nc.debug = true
wlan.debug = true

wlan.connect("Maciej6", "barabumbam", function() nc.start("pool.ntp.org", 7200) end)

local function printTime() 
	collectgarbage() print("RAM in printTime", node.heap())
	
	df.setEuropeTime(nc.current, 3600)
	
	print("Time:", string.format("%04u-%02u-%02u %02u:%02u:%02d", 
		df.year, df.month, df.day, df.hour, df.min, df.sec))
	print("Summer Time:", df.summerTime)
	print("Day of Week:", df.dayOfWeek)
end

tmr.alarm(2, 600000, tmr.ALARM_AUTO, printTime)
