-- #########################################################################
-- #### Date formatter is based on: https://github.com/daurnimator/luatz ###
-- #########################################################################
-- First you have to create instance by calling one of the dflic methods on "df".
-- Such instance provides dflic methods and fields dfined in "df" table.

DateFormatFactory = { }

local df = {
	year  = 1970,
	month = 1, -- range: 1 to 12
	day = 1, -- day of the month, range: 1-31
	hour = 0, -- range: 0 to 23
	min = 0, -- range: 1 to 60
	sec = 0, -- range: 1 to 60
	dayOfYear = 0, -- range: 1 to 361
	dayOfWeek = 0, -- range: 1 to 7 
	isLocalTime = false, -- true for local time with daylight saving
}

local mt = {
	__index = df
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

local function getDayOfYear(year, month, day)
	local yday = monthsToDaysCumulative[month]
	if month > 2 and isYearLeap(year) then
		yday = yday + 1
	end
	return yday + day
end

local function getDayOfWeek(year, month, day)
	if month < 3 then
		year = year - 1
	end
	return (year + isYearsLeapSince(year) + sakamoto[month] + day) % 7 + 1
end

local function carry (tens, units, base)
	if units >= base then
		tens  = tens + idiv (units , base)
		units = units % base
	end
	return tens , units
end

local function getYearOffset(ts)
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

-- gmt - "df" table based on GMT time
local function isDaylightSavingInUSA(gmt)
	-- January, february, and december are out.
    if gmt.month < 3 or gmt.month > 11 then return false end
    
    -- April to October are in
    if gmt.month > 3 and gmt.month < 11 then return true end
     
     local previousSunday = gmt.day - gmt.dayOfWeek;
     -- In march, we are DST if our previous sunday was on or after the 8th.
     if gmt.month == 3 then return previousSunday >= 8 end
      
      -- In november we must be before the first sunday to be dst.
      -- That means the previous sunday must be before the 1st.
      return previousSunday <= 0
end

-- gmt - "df" table based on GMT time
local function isDaylightSavingInCE(gmt)
	if gmt.month < 3 or gmt.month > 10 then return false end 
    if gmt.month > 3 and gmt.month < 10 then return true end 
    
   	local previousSunday = gmt.day - gmt.dayOfWeek
    if gmt.month == 3 then return previousSunday >= 25 end
    if gmt.month == 10 then return previousSunday < 25 end
    
	assert(false, "Error in isDaylightSavingInCE")
end

-- initializes "df" table with curent time stamp
--
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
	
	local rounds = 0
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
	self.dayOfYear = getDayOfYear(self.year, self.month, self.day)
	self.dayOfWeek = getDayOfWeek(self.year, self.month, self.day)
end

-- initializes "df" table with curent time stamp with GMT without daylight saving
--
-- ts - seconds since 1.1.1970
function DateFormatFactory:fromGMT(ts)
	obj = {}
	setmetatable(obj, mt)
	obj:setTime(ts)
	return obj
end

function df:format()
	return string.format("%04u-%02u-%02u %02u:%02u:%02d", self.year, self.month, 
		self.day, self.hour, self.min, self.sec)
end

mt.__tostring = function(df) return df:format() end