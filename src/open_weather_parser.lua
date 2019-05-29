require "json_list_parser"

-- parser api
owe_p = {
    forecast_days = 3,
    -- forecast for next 3 days. Contains only weather for the day from 6:00 to 21:00.
    -- Forecast for the first day reflects weather for current day, and if it's a night for a next day.
    forecast = {},

    -- forecast text for 3 days
    forecast_text = nil,
    current = {},
    has_weather = false,
    utc_offset = 3600
}

local dateFormat = DateFormat.new()

-- forecast by day
local tmp = {
    day_forecast_idx = 0,
    forecast = {}
}

local function reset()
    tmp.day_forecast_idx = 0
    tmp.forecast = {}
end

function owe_p.on_data_start()
    reset()
end

function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function update_current()
    local today = owe_p.forecast[1]
    local codes_str = {}
    for i = 1, today.codes_size do
        if i > 1 then
            table.insert(codes_str, ",")
        end
        table.insert(codes_str, today.codes[i])
    end
    owe_p.current.icons = table.concat(codes_str)
    local currentTemp = owe_p.forecast[1].temp
    if currentTemp < 0 then
        owe_p.current.temp = round(currentTemp)
    else
        owe_p.current.temp = round(currentTemp, 1)
    end
end

local function update_forecast_text()
    local text = {}
    for idx, weather in pairs(owe_p.forecast) do
        local temp_min = round(weather.temp_min)
        local temp_max = round(weather.temp_max)
        if idx > 1 then
            table.insert(text, " ")
            table.insert(text, string.char(3))
            table.insert(text, string.char(4))
            table.insert(text, " ")
        end
        table.insert(text, weather.day)
        table.insert(text, ":")
        table.insert(text, string.char(2))
        table.insert(text, temp_min)
        table.insert(text, " ")
        table.insert(text, string.char(1))
        table.insert(text, temp_max)
        table.insert(text, " ")

        local first = true
        for _, desc in pairs(weather.description) do
            if first then
                first = false
            else
                table.insert(text, ",")
            end
            table.insert(text, desc)
        end
    end
    owe_p.forecast_text = table.concat(text)
end

local function on_data_end()
    if log.is_info then
        log.info("OWE Got weather")
    end
    owe_p.forecast = tmp.forecast
    update_current()
    update_forecast_text()
    owe_p.has_weather = true
    reset()
end

--https://openweathermap.org/weather-conditions
local function map_code(condition)
    local mapped = 0

    -- ICON_IDX_MIX_SUN_RAIN
    if (condition >= 500 and condition < 511) then
        mapped = 0

        -- ICON_IDX_PARTLY_SUNNY
    elseif condition == 801 then
        mapped = 1

        -- ICON_IDX_RAIN
    elseif (condition >= 300 and condition < 400) or (condition >= 511 and condition < 600) then
        mapped = 2

        -- ICON_IDX_THUNDERSTORM
    elseif condition >= 200 and condition < 300 then
        mapped = 3

        -- ICON_IDX_MIX_SUN_THUNDERSTORM
        --   elseif code == 37 or code == 38 or code == 47 then
        --        mapped = 4

        -- ICON_IDX_MOON
        --    elseif code == 31 or code == 33 then
        --        mapped = 5

        -- ICON_IDX_MIX_SUN_SNOW
    elseif condition == 600 or condition == 620 or condition == 615 then
        mapped = 6

        -- ICON_IDX_SNOW
    elseif condition >= 600 and condition < 700 then
        mapped = 7

        -- ICON_IDX_CLOUDY
    elseif (condition >= 802 and condition < 900) or (condition >= 700 and condition < 800) then
        mapped = 8

        -- ICON_IDX_SUNNY
    elseif condition == 800 then
        mapped = 9
    end

    return mapped;
end

local function contains(tab, val)
    for _, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

local function update_day_forecast(df, weather)
    df.temp_min = math.min(df.temp_min, weather.temp_min)
    df.temp_max = math.max(df.temp_max, weather.temp_max)
    if not contains(df.description, weather.description) then
        table.insert(df.description, weather.description)
        local code = map_code(weather.id)
        if df.codes_size == 0 or (df.codes_size > 0 and df.codes[df.codes_size] ~= code) then
            table.insert(df.codes, code)
            df.codes_size = df.codes_size + 1
        end
    end
end

local function init_df(df)
    df.temp_min = 1000
    df.temp_max = -1000
    df.description = {}
    df.codes = {}
    df.codes_size = 0
    return df;
end

local function next_weather_chunk(doc)

    -- first day in weather chunk, or next day, like MON->TUE
    if tmp.day_forecast_idx == 0 or tmp.forecast[tmp.day_forecast_idx].day ~= doc.day then
        if tmp.day_forecast_idx == owe_p.forecast_days then
            return false
        end
        tmp.day_forecast_idx = tmp.day_forecast_idx + 1
        if tmp.forecast[tmp.day_forecast_idx] == nil then
            tmp.forecast[tmp.day_forecast_idx] = {}
        end
        local df = tmp.forecast[tmp.day_forecast_idx]
        init_df(df)
        df.temp = doc.temp
        df.day = doc.day
        tmp.forecast[tmp.day_forecast_idx] = df
    end
    update_day_forecast(tmp.forecast[tmp.day_forecast_idx], doc)
    return true
end

local function accept_time(date)
    local hourStr = date:sub(12, 13)
    local hour = tonumber(hourStr)
    return hour >= 6 and hour <= 21
end

function owe_p.on_next_document(doc)
    if tmp.day_forecast_idx == owe_p.forecast_days + 1 then
        return false
    end
    if not doc.dt_txt then
        return
    end
    local date = doc.dt_txt
    if not accept_time(date) then
        if log.is_debug then
            log.debug("OWE reject:", tostring(date))
        end
        return true
    end

    dateFormat:set_time(doc.dt, owe_p.utc_offset)

    local df = {} -- Day Forecast
    df.date = date
    df.day = dateFormat:get_day_of_week_up()
    df.temp_min = doc.main.temp_min
    df.temp_max = doc.main.temp_max
    df.temp = doc.main.temp

    local dw = doc.weather[1]
    df.description = dw.description
    df.id = dw.id

    if log.is_debug then
        log.debug("OWE next:", date, ",", df.day, ",", df.temp_min, ",", df.temp_max, ",", df.temp, ",", df.id, ",", df.description)
    end

    local next_doc = next_weather_chunk(df)
    if not next_doc then
        on_data_end()
    end
    return next_doc
end