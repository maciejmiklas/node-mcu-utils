local function start()
	tmr.stop(3)
	dofile("serialInit.lua")
end
tmr.alarm(3, 1500, tmr.ALARM_AUTO, start)