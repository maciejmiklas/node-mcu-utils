require "json_list_parser"

-- parser api
owe_p = {
    forecast_days = 3,
    -- forecast for next 3 days. Contains only weather for the day from 6:00 to 21:00.
    -- Forecast for the first day reflects weather for current day, and if it's a night for a next day.
    forecast = {},
    -- forecast as text for 3 days
    forecast_text = nil,
    current = {},
    has_weather = false,
    utc_offset = 3600
}

local df = DateFormat.new()

-- forecast by day
local tmp = {
    day_forecast = {},
    day_forecast_idx = 1,
    forecast = {}
}

local function reset()
    tmp.day_forecast = {}
    tmp.day_forecast_idx = 1
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
    local codes_str = ""
    for i = 1, today.codes_size do
        if i > 1 then
            codes_str = codes_str .. ","
        end
        codes_str = codes_str .. today.codes[i]
    end
    owe_p.current.icons = codes_str
    local currentTemp = owe_p.forecast[1].temp
    if currentTemp < 0 then
        owe_p.current.temp = round()
    else
        owe_p.current.temp = round(currentTemp, 1)
    end
end

local function update_forecast_text()
    local text = ""
    for idx, weather in pairs(owe_p.forecast) do
        local temp_min = round(weather.temp_min)
        local temp_max = round(weather.temp_max)
        if idx > 1 then
            text = text .. " " .. string.char(3) .. string.char(4) .. " "
        end
        text = text .. weather.day .. ":" .. string.char(2) .. temp_min .. " " .. string.char(1) .. temp_max .. " "
        for dIdx, desc in pairs(weather.description) do
            text = text .. desc
            if dIdx < weather.codes_size then
                text = text .. ","
            end
        end
    end
    owe_p.forecast_text = text
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

local function calculate_date_range(data)
    local el = {}
    el.temp_min = 1000
    el.temp_max = -1000
    el.description = {}
    el.codes = {}
    el.codes_size = 0
    el.day = data.day

    for idx, weather in pairs(data.el) do
        if idx == 1 then
            el.temp = weather.temp
        end
        el.temp_min = math.min(el.temp_min, weather.temp_min)
        el.temp_max = math.max(el.temp_max, weather.temp_max)
        if not contains(el.description, weather.description) then
            table.insert(el.description, weather.description)
            local code = map_code(weather.id)
            if el.codes_size == 0 or (el.codes_size > 0 and el.codes[el.codes_size] ~= code) then
                table.insert(el.codes, code)
                el.codes_size = el.codes_size + 1
            end
        end
    end
    tmp.forecast[tmp.day_forecast_idx] = el
end

local function next_document(el)
    if tmp.day_forecast.day == nil or tmp.day_forecast.day ~= el.day then
        if tmp.day_forecast.day then
            calculate_date_range(tmp.day_forecast)
            if tmp.day_forecast_idx == owe_p.forecast_days then
                on_data_end()
                return false
            end
            tmp.day_forecast_idx = tmp.day_forecast_idx + 1
        end
        tmp.day_forecast.day = el.day
        tmp.day_forecast.el = {}
    end
    table.insert(tmp.day_forecast.el, el)
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
        return true
    end

    df:set_time(doc.dt, owe_p.utc_offset)

    local val = {}
    val.date = date
    val.day = df:get_day_of_week_up()
    val.temp_min = doc.main.temp_min
    val.temp_max = doc.main.temp_max
    val.temp = doc.main.temp
    local dw = doc.weather[1]
    val.description = dw.description
    val.id = dw.id
    return next_document(val)
end