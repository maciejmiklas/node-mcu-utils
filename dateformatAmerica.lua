require "dateformat";

-- df - local winter time (without DLS)
local function isSummerTimeAmerica(df)
	if df.month < 3 or df.month > 11 then return false end

	if df.month > 3 and df.month < 11 then return true end

	local previousSunday = df.day - df.dayOfWeek;

	if df.month == 3 then
		if previousSunday >= 7 and previousSunday <= 13 and
			df.dayOfWeek == 1 and df.hour <= 1 then return false end
		if df.year >= 2020 then return previousSunday >= 7 end
		return previousSunday >= 8
	end

	if df.month == 11 then
		if df.day <= 7 and df.dayOfWeek == 1 and df.hour == 0 then return true end
		if df.year >= 2020 then return previousSunday < 0 end
		return previousSunday <= 0
	end

	assert(false, "Error in isSummerTimeAmerica")
end

-- initializes "df" table with USA time with daylight saving
--
-- utcSec - UTC seconds since 1.1.1970
-- utcOffset - UTC offset without daylight saving in seconds used to calculate local time from ts.
function df.setAmericaTime(utcSec, utcOffset)
	df.setTime(utcSec + utcOffset)
	df.summerTime = isSummerTimeAmerica(df)

	if df.summerTime then
		df.setTime(utcSec + utcOffset + 3600)
	else
		df.setTime(utcSec + utcOffset)
	end
end
