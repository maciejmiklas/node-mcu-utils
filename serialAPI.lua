require "wlan";

sapi = {pin = 4, debug = false, baud = 9600}
scmd = {}

local function onData(data)
	if sapi.debug then print("SAPI data:", data) end
	
	if data == nil then return end
	
	local dataLen = string.len(data);
	if dataLen < 5 then return end
	
	local status, err
	-- static command has 3 characters + \t\n
	if dataLen == 5 then
		local cmd = string.sub(data, 1, 3)
		if sapi.debug then print("SAPI CMD: '"..cmd.."'") end
		status, err = pcall(scmd[cmd])
		
	-- dynamic command has folowwing format: [3 chars command][space][param]	
	else
		local cmd = string.sub(data, 1, 3)
		local param = string.sub(data, 4, dataLen):gsub('%W','')
		if sapi.debug then print("SAPI CMD: '"..cmd.."', PAR: '"..param.."'") end
		status, err = pcall(scmd[cmd], param)
	end
	
	if status ~= true then uart.write(0, "ERR:"..err.."\n") end
end

-- return wifi status
function scmd.GWS()
	uart.write(0, wifi.sta.status().."\n")
end

-- return free ram
function scmd.GFR()
	uart.write(0, node.heap().."\n")
end

function sapi.start()
	gpio.mode(sapi.pin, gpio.OUTPUT)
	
	-- configure for 9600, 8N1, no echo
	uart.setup(0, sapi.baud, 8, uart.PARITY_NONE, uart.STOPBITS_1, 0)
	uart.on("data", '\n', onData , 0)
end