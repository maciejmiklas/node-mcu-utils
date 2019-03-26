require "date_format_america";

local testCnt = 0;
local function parseDate(expDate)
	local _, _, expYearStr, expMonthStr, expDayStr, expHourStr, expMinStr, expSecStr =
		string.find(expDate, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
	local expYear, expMonth, expDay = tonumber(expYearStr), tonumber(expMonthStr), tonumber(expDayStr)
	local expHour, expMin, expSec = tonumber(expHourStr), tonumber(expMinStr), tonumber(expSecStr)
	return 	expYear, expMonth, expDay, expHour, expMin, expSec
end

function format(df)
	return string.format("%04u-%02u-%02u %02u:%02u:%02d", df.year, df.month, 
		df.day, df.hour, df.min, df.sec)
end

function test_utc(df)
	for line in io.lines("test/unit/data/datesUTC.csv") do
		testCnt = testCnt + 1
		local _, _, tsStr, expDate = string.find(line, "(%d+),(.*)")
		local ts = tonumber(tsStr)
		local expYear, expMonth, expDay, expHour, expMin, expSec = parseDate(expDate);
		df:set_time_stamp(ts)
		local fromated = format(df)

		local msg =  tsStr.." -> "..expDate.." ~= "..fromated
		assert(fromated == expDate, msg)
		assert(df.summer_time == nil, msg)
		assert(df.year == expYear, msg)
		assert(df.month == expMonth, msg)
		assert(df.day == expDay, msg)
		assert(df.hour == expHour, msg)
		assert(df.min == expMin, msg)
		assert(df.sec == expSec, msg)
	end
end

function test_local(df, location, utc_offset, timeFunction)
	for line in io.lines("test/unit/data/dates"..location..".csv") do
		testCnt = testCnt + 1
		local _, _, utcSecTxt, expDate, expDls = string.find(line, "(%d+),(.*),(%d)")
		local utcSec = tonumber(utcSecTxt)
		timeFunction(df, utcSec, utc_offset)
		local fromated = format(df)
		local summer = (df.summer_time and "Summer" or "Winter")
		local expSummer = (expDls == "1" and "Summer" or "Winter")
		local msg =  location.." -> "..utcSecTxt.." -> "..expDate.."("..expSummer..") ~= "..fromated.."("..summer..")"
		assert(fromated == expDate, msg)
	end
end

function test_america(df, city, utc_offset)
	local location = "America_"..city
	local dateFactory = function(df, ts, utc_offset) return df:set_time(ts, utc_offset) end
	test_local(df, location, utc_offset, dateFactory)
end

print("Executing tests....")
df = DateFormat.new()
test_utc(df)
test_america(df, "Los_Angeles", -28800)

print("Done - Executed "..testCnt.." tests, all OK")
