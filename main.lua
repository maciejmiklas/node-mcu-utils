require "wlan"
require "ntp"
require "dateformat";

ntp.debug = true
wlan.debug = true

local function printTime(ts) 
	df:setTime(ts) 
	print("NTP time:", df)
end

ntp:registerResponseCallback(printTime)

wlan:connect("Maciej Miklas’s iPhone", "mysia2pysia", ntp.requestTime)