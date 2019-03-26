local tmrObj = tmr.create()

local function on_timer()
	dofile("_init.lua")
	tmrObj = nil
end

tmrObj:register(2000, tmr.ALARM_SINGLE, on_timer)
tmrObj:start()