require "dateformatEurope";
require "ntpClock";
require "wlan";

scl = {pin = 4, debug = false, utcOffset = 3600}
local api = {}

-- read time is seconds since 1.1.1970
function api.RTS()
	uart.write(0, nc.current.."\n")
end

-- return hours of local time in 24h format, e.g.: 23:11
function api.RH2()
	df.setEuropeTime(nc.current, scl.utcOffset)
	uart.write(0, string.format("%02u:%02u:%02d\n", df.hour, df.min, df.sec))
end

-- return date in format: yyyy-mm-dd
function api.RDU()
	df.setEuropeTime(nc.current, scl.utcOffset)
	uart.write(0, string.format("%04u-%02u-%02u\n", df.year, df.month, df.day))
end

-- return date and time (24h) in format: yyyy-mm-dd HHLmm:ss
function api.RF1()
	df.setEuropeTime(nc.current, scl.utcOffset)
	uart.write(0, string.format("%04u-%02u-%02u %02u:%02u:%02d\n",
		df.year, df.month, df.day, df.hour, df.min, df.sec))
end

-- return day of week as int, range: 1 to 7 starting from monday
function api.RDI()
	df.setEuropeTime(nc.current, scl.utcOffset)
	uart.write(0, df.dayOfWeek.."\n")
end

-- return day of week as 3 letter us text
function api.RDU()
	df.setEuropeTime(nc.current, scl.utcOffset)
	uart.write(0, df.getDayOfWeekUp().."\n")
end

-- return wifi status
function api.RWS()
	uart.write(0, wifi.sta.status().."\n")
end

-- return free ram
function api.RFR()
	uart.write(0, node.heap().."\n")
end

local function onData(data)
	-- each comman has 3 characters + \t\n
	if data == nil or string.len(data) ~= 5 then return end

	cmd = string.sub(data, 1, 3)
	if scl.debug then print("CMD: ", cmd) end

	api[cmd]()
end

--scl.debug = true
--nc.debug = true
--wlan.debug = true

gpio.mode(scl.pin, gpio.OUTPUT)

-- configure for 9600, 8N1, no echo
uart.setup(0, 115200, 8, uart.PARITY_NONE, uart.STOPBITS_1, 0)
uart.on("data", '\n', onData , 0)

wlan.setup(cred.ssid, cred.password)
wlan.execute(function() nc.start("pool.ntp.org", 3600) end)
