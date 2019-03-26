-- Date formatter is based on: https://github.com/daurnimator/luatz
--
-- First you have to create instance by calling one of the dflic methods on "df".
-- Such instance provides dflic methods and fields dfined in "df" table.
DateFormat = {
    year = 1970,
    month = 1, -- range: 1 to 12
    day = 1, -- day of the month, range: 1-31
    hour = 0, -- range: 0 to 23
    min = 0, -- range: 1 to 60
    sec = 0, -- range: 1 to 60
    day_off_week = 0, -- range: 1 to 7, starting from sunday
    summer_time = nil -- true for summer time, otherwise winter time. Nil for UTC.
}

function DateFormat.new()
    return setmetatable({}, { __index = DateFormat })
end

local monLengths = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

-- For Sakamoto's Algorithm (day of week)
local sakamoto = { 0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4 };
local weekDaysUP = { "SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT" }

local function idiv(n, d)
    return math.floor(n / d)
end

local function is_year_leap(y)
    if (y % 4) ~= 0 then
        return false
    elseif (y % 100) ~= 0 then
        return true
    else
        return (y % 400) == 0
    end
end

local function get_year_length(y)
    return is_year_leap(y) and 366 or 365
end

local function get_month_length(m, y)
    if m == 2 then
        return is_year_leap(y) and 29 or 28
    else
        return monLengths[m]
    end
end

local function is_years_leap_since(year)
    return idiv(year, 4) - idiv(year, 100) + idiv(year, 400)
end

local function carry(tens, units, base)
    if units >= base then
        tens = tens + idiv(units, base)
        units = units % base
    end
    return tens, units
end

-- range: 1 to 7, starting from sunday
local function get_day_of_week(year, month, day)
    if month < 3 then
        year = year - 1
    end
    return (year + is_years_leap_since(year) + sakamoto[month] + day) % 7 + 1
end

local function get_year_offset(ts)
    local year, offset

    if ts >= 1577836800 then
        year, offset = 2020, 1577836800 -- 1.1.2020

    elseif ts >= 1420070400 then
        year, offset = 2015, 1420070400 -- 1.1.2015

    else
        year, offset = 1970, 0
    end
    return year, offset
end

-- initializes "df" table with curent time stamp
--
-- ts - seconds since 1.1.1970
function DateFormat:set_time_stamp(ts)
    local year, offset = get_year_offset(ts)
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
        local month_length = get_month_length(month + 1, year)
        if day < month_length then break end
        day = day - month_length
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
    self.day_off_week = get_day_of_week(self.year, self.month, self.day)
end

function DateFormat:get_day_of_week_up()
    return weekDaysUP[self.day_off_week]
end
