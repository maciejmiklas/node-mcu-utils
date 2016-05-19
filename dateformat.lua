-- #########################################################################
-- #### Date formatter is based on: https://github.com/daurnimator/luatz ###
-- #########################################################################
df = {
	year  = 1970,
	month = 1,
	day   = 1,
	hour  = 0,
	min   = 0,
	sec   = 0
}

local monLengths = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
local monthsToDaysCumulative = {0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334}

-- For Sakamoto's Algorithm (day of week)
local sakamoto = {0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4};
		
local function idiv(n, d)
	return math.floor(n/d)
end

local function isYearLeap(y)
	if (y % 4) ~= 0 then
		return false
	elseif (y % 100) ~= 0 then
		return true
	else
		return (y % 400) == 0
	end
end

local function getYearLength(y)
	return isYearLeap(y) and 366 or 365
end

local function getMonthLength(m, y)
	if m == 2 then
		return isYearLeap(y) and 29 or 28
	else
		return monLengths[m]
	end
end

local function isYearsLeapSince(year)
	return idiv(year, 4) - idiv(year, 100) + idiv(year, 400)
end

function df:getDayOfYear()
	local yday = monthsToDaysCumulative[self.month]
	if self.month > 2 and isYearLeap(self.year) then
		yday = yday + 1
	end
	return yday + self.day
end

function df:getDayOfWeek()
	if self.month < 3 then
		self.year = self.year - 1
	end
	return (self.year + isYearsLeapSince(self.year) + sakamoto[self.month] + self.day) % 7 + 1
end

local function carry (tens, units, base)
	if units >= base then
		tens  = tens + idiv (units , base)
		units = units % base
	end
	return tens , units
end

function getYearOffset(ts)
	local year, offset
	if ts >= 1735689600 then
		year, offset = 2025, 1735689600 -- 1.1.2015
	
	elseif ts >= 1577836800 then
		year, offset = 2020, 1577836800 -- 1.1.2020
	
	elseif ts >= 1420070400 then
		year, offset = 2015, 1420070400 -- 1.1.2015
	
	elseif ts >= 1262304000 then
		year, offset = 2010, 1262304000 -- 1.1.2010
	
	elseif ts >= 946684800 then
		year, offset = 2000, 946684800 -- 1.1.2000
	
	elseif ts >= 631152000 then
		year, offset = 1990, 631152000 -- 1.1.1990
	
	elseif ts >= 315532800 then
		year, offset = 1980, 315532800 -- 1.1.1980
	
	else
		year, offset = 1970, 0
	end
	return year, offset
end

-- ts - seconds since 1.1.1970
function df:setTime(ts)
	local year, offset = getYearOffset(ts)
	local month = 0
	local day = 0
	local hour = 0 
	local min = 0
	local sec = ts - offset

	-- Propagate out of range values up
	-- e.g. if `min` is 70, `hour` increments by 1 and `min` becomes 10
	min, sec = carry(min, sec, 60)
	hour, min = carry(hour, min, 60)
	day, hour = carry(day, hour, 24)
	
	rounds = 0
	while true do
	rounds = rounds + 1
		local monthLength = getMonthLength(month + 1 , year)
		if day < monthLength then break end
		day = day - monthLength
		month = month + 1
		if month >= 12 then
			month = 0
			year = year + 1
		end
	end
	
	self.year = year
	self.month = month + 1
	self.day = day + 1
	self.hour = hour 
	self.min = min
	self.sec = sec
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