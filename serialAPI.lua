require "wlan";

sapi = {pin = 4, debug = false, baud = 115200}
scmd = {}

local function onData(data)
	-- each comman has 3 characters + \t\n
	if data == nil or string.len(data) ~= 5 then return end

	cmd = string.sub(data, 1, 3)
	if sapi.debug then print("CMD: ", cmd) end

	scmd[cmd]()
end

-- return wifi status
function scmd.GWS()
	uart.write(0, wifi.sta.status().."\n")
end

-- return free ram
function scmd.GFR()
	uart.write(0, node.heap().."\n")
end

function sapi.setup()
	gpio.mode(sapi.pin, gpio.OUTPUT)
	
	-- configure for 9600, 8N1, no echo
	uart.setup(0, sapi.baud, 8, uart.PARITY_NONE, uart.STOPBITS_1, 0)
	uart.on("data", '\n', onData , 0)
end