require "date_format_europe";

local testCnt = 0;
local function parseDate(expDate)
    local _, _, expYearStr, expMonthStr, expDayStr, expHourStr, expMinStr, expSecStr =
    string.find(expDate, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
    local expYear, expMonth, expDay = tonumber(expYearStr), tonumber(expMonthStr), tonumber(expDayStr)
    local expHour, expMin, expSec = tonumber(expHourStr), tonumber(expMinStr), tonumber(expSecStr)
    return expYear, expMonth, expDay, expHour, expMin, expSec
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

        local msg = tsStr .. " -> " .. expDate .. " ~= " .. fromated
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
    for line in io.lines("test/unit/data/dates" .. location .. ".csv") do
        testCnt = testCnt + 1
        local _, _, utcSecTxt, expDate, expDls = string.find(line, "(%d+),(.*),(%d)")
        local utcSec = tonumber(utcSecTxt)
        timeFunction(utcSec, utc_offset)
        local fromated = format(df)
        local summer = (df.summer_time and "Summer" or "Winter")
        local expSummer = (expDls == "1" and "Summer" or "Winter")
        local msg = location .. " -> " .. utcSecTxt .. " -> " .. expDate .. "(" .. expSummer .. ") ~= " .. fromated .. "(" .. summer .. ")"
        assert(fromated == expDate, msg)
    end
end

function test_europe(df, city, utc_offset)
    local location = "Europe_" .. city
    test_local(df, location, utc_offset, function(ts, utc_offset) return df:set_time(ts, utc_offset) end)
end

function test_different_instances()
    --1466765445,2016-06-24 12:50:45,1
    local df1 = DateFormat.new()
    df1:set_time(1466765445, 3600)
    local formated1 = format(df1)
    assert("2016-06-24 12:50:45" == formated1, formated1)

    --1467547980,2016-07-03 14:13:00,1
    local df2 = DateFormat.new()
    df2:set_time(1467547980, 3600)
    local formated2 = format(df2)
    assert("2016-07-03 14:13:00" == formated2, formated2)

    formated1 = format(df1)
    assert("2016-06-24 12:50:45" == formated1, formated1)

    --1470679950,2016-08-08 20:12:30,1
    df1:set_time(1470679950, 3600)
    formated1 = format(df1)
    assert("2016-08-08 20:12:30" == formated1, formated1)

    formated2 = format(df2)
    assert("2016-07-03 14:13:00" == formated2, formated2)
end

print("Executing tests....")
df = DateFormat.new()
test_different_instances()
test_utc(df)
test_europe(df, "London", 0)
test_europe(df, "Warsaw", 3600)
test_europe(df, "Bucharest", 7200)

print("Done - Executed " .. testCnt .. " tests, all OK")
