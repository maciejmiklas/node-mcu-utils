print("RAM init", node.heap())

require "wlan"
require "ntp"
require "dateformat";

print("RAM require", node.heap())

ntp.debug = true
wlan.debug = true

local function printTime(ts) 
	print("RAM before printTime", node.heap())
	
	df.setGmtTime(ts) 
	print("NTP time:", df)
	
	print("RAM after printTime", node.heap())
end

ntp:registerResponseCallback(printTime)

wlan:connect("Maciej Miklas’s iPhone", "mysia2pysia", ntp.requestTime)

print("RAM callbacks", node.heap())

