local tmrObj = tmr.create()

local function onTimer()
	dofile("_init.lua")
	tmrObj = nil
end

tmrObj:register(2000, tmr.ALARM_SINGLE, onTimer)
tmrObj:start()