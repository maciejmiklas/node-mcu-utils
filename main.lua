collectgarbage() print("RAM init", node.heap())

require "wlan"
require "ntp"
require "dateformat";

collectgarbage() print("RAM require", node.heap())

ntp = NtpFactory:fromDefaultServer():withDebug()
wlan.debug = true

local function printTime(ts) 
	collectgarbage() print("RAM before printTime", node.heap())
	
	df = DateFormatFactory:asUTC(ts)
	print("NTP time:", df)
	
	collectgarbage() print("RAM after printTime", node.heap())
end

ntp:registerResponseCallback(printTime)

wlan.connect("Maciej Miklas’s iPhone", "barabumbam", function() ntp:requestTime() end)

collectgarbage() print("RAM callbacks", node.heap())
 
