--const char CMD_GET_TIME_HH[] = { 'C', 'H', 'H', '\r', '\n', '\0' };
--const char CMD_GET_TIME_MM[] = { 'C', 'M', 'I', '\r', '\n', '\0' };
--const char CMD_GET_DATE_DDD[] = { 'C', 'D', '3', '\r', '\n', '\0' };
--const char CMD_GET_DATE_DD[] = { 'C', 'D', 'D', '\r', '\n', '\0' };
--const char CMD_GET_DATE_MM[] = { 'C', 'M', 'M', '\r', '\n', '\0' };
--const char CMD_GET_ESP_STATUS[] = { 'G', 'S', 'S', '\r', '\n', '\0' };
--const char CMD_GET_WEATHER_STATUS[] = { 'W', 'S', 'T', '\r', '\n', '\0' };
--
--const char CMD_GET_CUR_TEMP[] = { 'W', 'C', 'W', ' ', 't', 'e', 'm', 'p', '\r', '\n', '\0' };
--const uint8_t CMD_GET_CUR_TEMP_SIZE = 10;
--
--const uint8_t CMD_GET_WEATHER_DAY_IDX = 2;
--
--const uint8_t CMD_GET_WEATHER_DAY_SIZE = 9;
--char CMD_GET_WEATHER_DAY[] = { 'W', 'F', '1', ' ', 'd', 'a', 'y', '\r', '\n', '\0' };
--
--const uint8_t CMD_GET_WEATHER_TEXT_SIZE = 10;
--char CMD_GET_WEATHER_TEXT[] = { 'W', 'F', '1', ' ', 't', 'e', 'x', 't', '\r', '\n', '\0' };
--
--const uint8_t CMD_GET_WEATHER_LOW_SIZE = 9;
--char CMD_GET_WEATHER_LOW[] = { 'W', 'F', '1', ' ', 'l', 'o', 'w', '\r', '\n', '\0' };
--
--const uint8_t CMD_GET_WEATHER_HIGH_SIZE = 10;
--char CMD_GET_WEATHER_HIGH[] = { 'W', 'F', '1', ' ', 'h', 'i', 'g', 'h', '\r', '\n', '\0' };
--
--const uint8_t CMD_GET_WEATHER_CODE_DAY_IDX = 4;
--const uint8_t CMD_GET_WEATHER_CODE_SIZE = 7;
--char CMD_GET_WEATHER_CODE[] = { 'W', 'W', 'C', ' ', '1', '\r', '\n', '\0' };

require "openWeather";

local function ready()
    if owe_net.weather ~= nil then
        return true
    end
    uart.write(0, "ER\n")
    return false
end

function scmd.WST()
    if owe_net.weather ~= nil then
        uart.write(0, "OK\n")
    else
        uart.write(0, "ER\n")
    end
end

-- current weather
-- Possible params:
-- - temp - current temp 
function scmd.WCW(param)
    if ready() == false then
        return
    end
    uart.write(0, owe_net.weather[0][param] .. '\n')
end

-- formatted weather text for 3 days intenden to be used with LEAClock
function scmd.WFF(param)
    if ready() == false then
        return
    end
    uart.write(0, 'TODO\n')
end

-- "scmd.WFx" returns forecast the whole day, where x is day: 1 - today, 2 - tommorow, and so on. 
-- Possible params:
-- - day_text - description
-- - day_min - min temp diring the day 
-- - day_max - max temp diring the day
-- - night_min - min temp diring the day 
-- - night_max - min temp diring the day
function scmd.WF1(param)
    if ready() == false then
        return
    end
    uart.write(0, owe_net.weather[1][param] .. '\n')
end

function scmd.WF2(param)
    if ready() == false then
        return
    end
    uart.write(0, owe_net.weather[2][param] .. '\n')
end

function scmd.WF3(param)
    if ready() == false then
        return
    end
    uart.write(0, owe_net.weather[3][param] .. '\n')
end

-- returns weather code for given day as 1, 2 and 3, where 1 is today, 2 tomorrow, and so on.
function scmd.WWC(dayStr)
    if ready() == false then
        return
    end
    local day = tonumber(dayStr)
    uart.write(0, mapCode(owe_net.weather[day].code) .. '\n')
end

-- https://developer.yahoo.com/weather/documentation.html#codes
local function mapCode(codeStr)
    local code = tonumber(codeStr)

    local mapped = code;

    -- ICON_IDX_MIX_SUN_RAIN
    if code == 40 or code == 46 then
        mapped = 0

        -- ICON_IDX_PARTLY_SUNNY
    elseif code == 44 or code == 30 then
        mapped = 1

        -- ICON_IDX_RAIN
    elseif code == 9 or code == 11 or code == 12 or code == 17 or code == 35 or code == 19 or
            code == 5 or code == 6 or code == 7 or code == 8 or code == 10 or code == 18 then
        mapped = 2

        -- ICON_IDX_THUNDERSTORM
    elseif code == 0 or code == 1 or code == 2 or code == 3 or code == 4 or code == 45 or code == 39 then
        mapped = 3

        -- ICON_IDX_MIX_SUN_THUNDERSTORM
    elseif code == 37 or code == 38 or code == 47 then
        mapped = 4

        -- ICON_IDX_MOON
    elseif code == 31 or code == 33 then
        mapped = 5

        -- ICON_IDX_MIX_SUN_SNOW
    elseif code == 14 then
        mapped = 6

        -- ICON_IDX_SNOW
    elseif code == 13 or code == 15 or code == 16 or code == 43 or code == 41 or code == 42 then
        mapped = 7

        -- ICON_IDX_CLOUDY
    elseif code == 20 or code == 21 or code == 22 or code == 23 or code == 24 or code == 25 or code == 26 or code == 27 or code == 28
            or code == 29 then
        mapped = 8

        -- ICON_IDX_SUNNY
    elseif code == 34 or code == 36 or code == 32 then
        mapped = 9
    end

    return mapped;
end
