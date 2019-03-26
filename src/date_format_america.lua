require "date_format";

-- local winter time (without DLS)
function DateFormat:is_summer_time_america()
    if self.month < 3 or self.month > 11 then return false end

    if self.month > 3 and self.month < 11 then return true end

    local previous_sunday = self.day - self.day_off_week;

    if self.month == 3 then
        if previous_sunday >= 7 and previous_sunday <= 13 and
                self.day_off_week == 1 and self.hour <= 1 then return false
        end
        if self.year >= 2020 then return previous_sunday >= 7 end
        return previous_sunday >= 8
    end

    if self.month == 11 then
        if self.day <= 7 and self.day_off_week == 1 and self.hour == 0 then return true end
        if self.year >= 2020 then return previous_sunday < 0 end
        return previous_sunday <= 0
    end

    assert(false)
end

-- initializes DateFormat table with USA time with daylight saving
--
-- utcSec - UTC seconds since 1.1.1970
-- utc_offset - UTC offset without daylight saving in seconds used to calculate local time from ts.
function DateFormat:set_time(utcSec, utc_offset)
    self:set_time_stamp(utcSec + utc_offset)
    self.summer_time = self:is_summer_time_america()

    if self.summer_time then
        self:set_time_stamp(utcSec + utc_offset + 3600)
    else
        self:set_time_stamp(utcSec + utc_offset)
    end
end
