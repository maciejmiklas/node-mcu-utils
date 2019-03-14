require "dateformat";

-- local winter time (without DLS)
function DateFormat:isSummerTimeAmerica()
    if self.month < 3 or self.month > 11 then return false end

    if self.month > 3 and self.month < 11 then return true end

    local previousSunday = self.day - self.dayOfWeek;

    if self.month == 3 then
        if previousSunday >= 7 and previousSunday <= 13 and
                self.dayOfWeek == 1 and self.hour <= 1 then return false
        end
        if self.year >= 2020 then return previousSunday >= 7 end
        return previousSunday >= 8
    end

    if self.month == 11 then
        if self.day <= 7 and self.dayOfWeek == 1 and self.hour == 0 then return true end
        if self.year >= 2020 then return previousSunday < 0 end
        return previousSunday <= 0
    end

    assert(false)
end

-- initializes DateFormat table with USA time with daylight saving
--
-- utcSec - UTC seconds since 1.1.1970
-- utcOffset - UTC offset without daylight saving in seconds used to calculate local time from ts.
function DateFormat:setTime(utcSec, utcOffset)
    self:setTimeStamp(utcSec + utcOffset)
    self.summerTime = self:isSummerTimeAmerica()

    if self.summerTime then
        self:setTimeStamp(utcSec + utcOffset + 3600)
    else
        self:setTimeStamp(utcSec + utcOffset)
    end
end
