require "dateformat";

testCnt = 0;
errCnt = 0;
local function parseDate(expDate)
	local _, _, expYearStr, expMonthStr, expDayStr, expHourStr, expMinStr, expSecStr =
		string.find(expDate, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
	local expYear, expMonth, expDay = tonumber(expYearStr), tonumber(expMonthStr), tonumber(expDayStr)
	local expHour, expMin, expSec = tonumber(expHourStr), tonumber(expMinStr), tonumber(expSecStr)
	return 	expYear, expMonth, expDay, expHour, expMin, expSec
end

function testUTC()
	for line in io.lines("test/data/datesUTC.csv") do
		testCnt = testCnt + 1
		local _, _, tsStr, expDate = string.find(line, "(%d+),(.*)")
		local ts = tonumber(tsStr)
		local expYear, expMonth, expDay, expHour, expMin, expSec = parseDate(expDate);
		local df = DateFormatFactory:asUTC(ts)
		local fromated = df:format()

		local msg =  tsStr.." -> "..expDate.." ~= "..fromated
		assert(fromated == expDate, msg)
		assert(ts == df.utcSec, msg)
		assert(df.lt.zone == nil, msg)
		assert(df.year == expYear, msg)
		assert(df.month == expMonth, msg)
		assert(df.day == expDay, msg)
		assert(df.hour == expHour, msg)
		assert(df.min == expMin, msg)
		assert(df.sec == expSec, msg)
	end
end

function testDST(location, utcOffset, dateFactory)
	for line in io.lines("test/data/dates"..location..".csv") do
		testCnt = testCnt + 1
		local _, _, utcSecTxt, expDate, expDls = string.find(line, "(%d+),(.*),(%d)")
		local utcSec = tonumber(utcSecTxt)
		local expYear, expMonth, expDay, expHour, expMin, expSec = parseDate(expDate);
		local df = dateFactory(utcSec, utcOffset)
		local fromated = df:format()
		local summer = (df.lt.summerTime and "Summer" or "Winter")
		local expSummer = (expDls == "1" and "Summer" or "Winter")
		local msg =  location.." -> "..utcSecTxt.." -> "..expDate.."("..expSummer..") ~= "..fromated.."("..summer..")"
		if(fromated ~= expDate) then
			errCnt = errCnt + 1
			print("Error", msg)
		end
	end
end

function testEurope(city, utcOffset)
	local location = "Europe_"..city
	local dateFactory = function(ts, utcOffset) return DateFormatFactory:asEurope(ts, utcOffset) end
	testDST(location, utcOffset, dateFactory)
end

function testAmerica(city, utcOffset)
	local location = "America_"..city
	local dateFactory = function(ts, utcOffset) return DateFormatFactory:asAmerica(ts, utcOffset) end
	testDST(location, utcOffset, dateFactory)
end

print("Executing tests....")
testUTC()
testEurope("London", 0)
testEurope("Warsaw", 3600)
testEurope("Bucharest", 7200)
testAmerica("Los_Angeles", -28800)

print("Done - Executed "..testCnt.." tests, errors: "..errCnt)
