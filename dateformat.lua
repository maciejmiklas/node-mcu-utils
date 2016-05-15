-- This file is based on: https://github.com/daurnimator/luatz
df = {
	year  = 1970,
	month = 1,
	day   = 1,
	hour  = 0,
	min   = 0,
	sec   = 0,
	yday  = 0,
	wday  = 0
}

local mon_lengths = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
local months_to_days_cumulative = {0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334}

-- For Sakamoto's Algorithm (day of week)
local sakamoto = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4};
		
local function idiv(n, d)
	return math.floor(n/d)
end

local function is_leap ( y )
	if (y % 4) ~= 0 then
		return false
	elseif (y % 100) ~= 0 then
		return true
	else
		return (y % 400) == 0
	end
end

local function year_length ( y )
	return is_leap ( y ) and 366 or 365
end

local function month_length ( m , y )
	if m == 2 then
		return is_leap ( y ) and 29 or 28
	else
		return mon_lengths [ m ]
	end
end

local function leap_years_since ( year )
	return idiv ( year , 4 ) - idiv ( year , 100 ) + idiv ( year , 400 )
end

local function day_of_year ( day , month , year )
	local yday = months_to_days_cumulative [ month ]
	if month > 2 and is_leap ( year ) then
		yday = yday + 1
	end
	return yday + day
end

local function day_of_week ( day , month , year )
	if month < 3 then
		year = year - 1
	end
	return ( year + leap_years_since ( year ) + sakamoto[month] + day ) % 7 + 1
end

local function carry ( tens , units , base )
	if units >= base then
		tens  = tens + idiv ( units , base )
		units = units % base
	elseif units < 0 then
		tens  = tens - 1 + idiv ( -units , base )
		units = base - ( -units % base )
	end
	return tens , units
end

-- ts - seconds since 1.1.1970
function df:setTime(ts)
	year = 1970
	month = 0
	day = 0
	hour = 0 
	min = 0
	sec = ts

	-- Propagate out of range values up
	-- e.g. if `min` is 70, `hour` increments by 1 and `min` becomes 10
	-- This has to happen for all columns after borrowing, as lower radixes may be pushed out of range
	min   , sec   = carry ( min   , sec   , 60 ) -- TODO: consider leap seconds?
	hour  , min   = carry ( hour  , min   , 60 )
	day   , hour  = carry ( day   , hour  , 24 )
	-- Ensure `day` is not underflowed
	-- Add a whole year of days at a time, this is later resolved by adding months
	-- TODO[OPTIMIZE]: This could be slow if `day` is far out of range
	while day < 0 do
		year = year - 1
		day  = day + year_length ( year )
	end
	year , month = carry ( year , month , 12 )

	-- TODO[OPTIMIZE]: This could potentially be slow if `day` is very large
	while true do
		local i = month_length ( month + 1 , year )
		if day < i then break end
		day = day - i
		month = month + 1
		if month >= 12 then
			month = 0
			year = year + 1
		end
	end

	-- Now we can place `day` and `month` back in their normal ranges
	-- e.g. month as 1-12 instead of 0-11
	month = month + 1
	day = day + 1
	
	self.year = year
	self.month = month
	self.day = day
	self.hour = hour 
	self.min = min
	self.sec = sec
	self.yday  = day_of_year ( day , month , year )
	self.wday  = day_of_week ( day , month , year )
end

function df:format()
	return string.format("%04u-%02u-%02u %02u:%02u:%02d", df.year, df.month, 
		df.day, df.hour, df.min, df.sec)
end

local function tostring(df)
	return df:format()
end

local mt = {
	__tostring = tostring
}
setmetatable(df, mt)