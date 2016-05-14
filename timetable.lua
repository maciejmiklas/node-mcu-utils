-- This Lua file is based on: https://github.com/daurnimator/luatz - Thanks !

-- 55886
-- 50720

local function idiv(n, d)
	return math.floor(n/d)
end


local mon_lengths = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
-- Number of days in year until start of month; not corrected for leap years
local months_to_days_cumulative = { 0 }
for i = 2, 12 do
	months_to_days_cumulative [ i ] = months_to_days_cumulative [ i-1 ] + mon_lengths [ i-1 ]
end
-- For Sakamoto's Algorithm (day of week)
local sakamoto = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4};

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

local function borrow ( tens , units , base )
	local frac = tens % 1
	units = units + frac * base
	tens = tens - frac
	return tens , units
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

-- Modify parameters so they all fit within the "normal" range
local function normalise ( year , month , day , hour , min , sec )
	-- `month` and `day` start from 1, need -1 and +1 so it works modulo
	month , day = month - 1 , day - 1

	-- Convert everything (except seconds) to an integer
	-- by propagating fractional components down.
	year  , month = borrow ( year  , month , 12 )
	-- Carry from month to year first, so we get month length correct in next line around leap years
	year  , month = carry ( year , month , 12 )
	month , day   = borrow ( month , day   , month_length ( math.floor ( month + 1 ) , year ) )
	day   , hour  = borrow ( day   , hour  , 24 )
	hour  , min   = borrow ( hour  , min   , 60 )
	min   , sec   = borrow ( min   , sec   , 60 )

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
	month , day = month + 1 , day + 1
	return year , month , day , hour , min , sec
end

local timetable_methods = { }

function timetable_methods:unpack ( )
	return assert ( self.year  , "year required" ) ,
		assert ( self.month , "month required" ) ,
		assert ( self.day   , "day required" ) ,
		self.hour or 12 ,
		self.min  or 0 ,
		self.sec  or 0 ,
		self.yday ,
		self.wday
end

function timetable_methods:normalise ( )
	local year , month , day
	year , month , day , self.hour , self.min , self.sec = normalise ( self:unpack ( ) )

	self.day   = day
	self.month = month
	self.year  = year
	self.yday  = day_of_year ( day , month , year )
	self.wday  = day_of_week ( day , month , year )

	return self
end
timetable_methods.normalize = timetable_methods.normalise -- American English

function timetable_methods:rfc_3339 ( )
	local year, month, day, hour, min, fsec = self:unpack()
	local sec, msec = borrow(fsec, 0, 1000)
	msec = math.floor(msec)
	return string.format ("%04u-%02u-%02uT%02u:%02u:%02d.%03d" , year , month , day , hour , min , sec , msec )
end

local timetable_mt


timetable_mt = {
	__index    = timetable_methods ;
	__tostring = timetable_methods.rfc_3339 ;
}

local function new_timetable ( ts )
	timetable = {
		year  = 1970 ;
		month = 1 ;
		day   = 1 ;
		hour  = 0 ;
		min   = 0 ;
		sec   = ts ;
		yday  = 0 ;
		wday  = 0 ;
	}
	setmetatable (timetable, timetable_mt)
	return timetable
end

function new_from_timestamp(ts)
	return new_timetable(ts):normalise ( )
end

return {
	is_leap = is_leap ;
	day_of_year = day_of_year ;
	day_of_week = day_of_week ;
	normalise = normalise ;

	new = new_timetable ;
	new_from_timestamp = new_from_timestamp ;
	cast = cast_timetable ;
	timetable_mt = timetable_mt ;
}
