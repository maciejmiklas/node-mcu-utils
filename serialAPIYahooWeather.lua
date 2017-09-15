require "yahooWeather";

local function ready()
	if yaw.weather ~= nil then
		return true
	end
	uart.write(0, "XX\n")
	return false
end

function scmd.YCW(param)
  if ready() == false then
    return
  end
  uart.write(0, yaw.weather[0][param]..'\n')
end

-- "scmd.YFx" returns forecast for given param, where x is day: 1 - today, 2 - tommorow, and so on. 
-- Possible params can be found at: yahooWeather.lua -> yaw.weather
function scmd.YF1(param)
	if ready() == false then
		return
	end
	uart.write(0, yaw.weather[1][param]..'\n')
end

function scmd.YF2(param)
	if ready() == false then
		return
	end
	uart.write(0, yaw.weather[2][param]..'\n')
end

function scmd.YF3(param)
	if ready() == false then
		return
	end
	uart.write(0, yaw.weather[3][param]..'\n')
end

-- https://developer.yahoo.com/weather/documentation.html#codes
local function mapCode(codeStr)
	local code = tonumber(codeStr)
	
	local mapped = code;	
	
	-- ICON_IDX_MIX_SUN_RAIN
	if code == 40 or code == 46 then
		mapped = 0
		
	-- ICON_IDX_PARTLY_SUNNY
	elseif code == 44  or code == 30 then
		mapped = 1

	-- ICON_IDX_RAIN
	elseif code == 9 or code == 11 or code == 12 or code == 17  or code == 35 or code == 19 or 
			code == 5 or code == 6 or code == 7 or code == 8 or code == 10 or code == 18 then		
		mapped = 2
		
	-- ICON_IDX_THUNDERSTORM
	elseif code == 0 or code == 1 or code == 2 or code == 3 or code == 4 or code == 45 or code == 39 then
		mapped = 3
		
	-- ICON_IDX_MIX_SUN_THUNDERSTORM		
	elseif code == 37 or code == 38  or code == 47 then
		mapped = 4
		
	-- ICON_IDX_MOON		
	elseif code == 31 or code == 33 then
		mapped = 5	
			
	-- ICON_IDX_MIX_SUN_SNOW		
	elseif code == 14 then
		mapped = 6			

	-- ICON_IDX_SNOW		
	elseif code == 13 or code == 15 or code == 16 or code == 43 or code == 41  or code == 42 then
		mapped = 7			
		
	-- ICON_IDX_CLOUDY		
	elseif code == 20 or code == 21 or code == 22 or code == 23 or code == 24 or code == 25 or code == 26 or code == 27 or code == 28 
			 or code == 29 then
		mapped = 8		
			
	-- ICON_IDX_SUNNY		
	elseif code == 34 or code == 36 or code == 32 then
		mapped = 9	
	end	
	
	return mapped;
end

-- returns weather code for given day as 1, 2 and 3, where 1 is today, 2 tomorrow, and so on.
function scmd.YWC(dayStr)
	if ready() == false then
		return
	end
	local day = tonumber(dayStr)
	uart.write(0, mapCode(yaw.weather[day].code)..'\n')
end
