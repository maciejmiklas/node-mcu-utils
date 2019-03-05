require "jsonListParser"

-- parser api
owe_p = {
    forecastDays = 3,
    -- forecast for next 3 days. Contains only weather for the day from 6:00 to 21:00.
    -- Forecast for the first day reflects weather for current day, and if it's a night for a next day.
    forecast = {},
    -- forecast as text for 3 days
    forecastText = nil,
    current = {},
    hasWeather = false
}

-- forecast by day
local tmp = {
    dayForecast = {},
    dayForecastIdx = 1,
    forecast = {}
}

local function reset()
    tmp.dayForecast = {}
    tmp.dayForecastIdx = 1
    tmp.forecast = {}
end

function owe_p.onDataStart()
    reset()
end

function roundTmp(val)
    return math.floor(val * 10 + 0.5) / 10
end

local function updateCurrent()
    local today = owe_p.forecast[1]
    local codesStr = ""
    for i = 1, today.codesSize do
        if i > 1 then codesStr = codesStr .. "," end
        codesStr = codesStr .. today.codes[i]
    end
    owe_p.current.icons = codesStr
    owe_p.current.temp = owe_p.forecast[1].temp
end

local function updateForecastText()
    local text = ""
    for idx, weather in pairs(owe_p.forecast) do
        local tempMin = roundTmp(weather.tempMin)
        local tempMax = roundTmp(weather.tempMax)
        if idx > 1 then
            text = text .. " " .. string.char(3) .. string.char(4) .. " "
        end
        text = text .. weather.day .. ": " .. string.char(2) .. tempMin .. " " .. string.char(1) .. tempMax
        for dIdx, desc in pairs(weather.description) do
            text = text .. " " .. desc
            if dIdx < weather.codesSize then
                text = text .. ","
            end
        end
    end
    owe_p.forecastText = text
end

local function onDataEnd()
    if log.isInfo then log.info("Got weather") end
    owe_p.forecast = tmp.forecast
    updateCurrent()
    updateForecastText()
    owe_p.hasWeather = true
    reset()
end

--https://openweathermap.org/weather-conditions
local function mapCode(condition)
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

local function calculateDateRange(data)
    local el = {}
    el.tempMin = 1000
    el.tempMax = -1000
    el.description = {}
    el.codes = {}
    el.codesSize = 0
    el.day = data.day

    for idx, weather in pairs(data.el) do
        if idx == 1 then
            el.temp = weather.temp
        end
        el.tempMin = math.min(el.tempMin, weather.tempMin)
        el.tempMax = math.max(el.tempMax, weather.tempMax)
        if not contains(el.description, weather.description) then
            table.insert(el.description, weather.description)
            table.insert(el.codes, mapCode(weather.id))
            el.codesSize = el.codesSize + 1
        end
    end
    tmp.forecast[tmp.dayForecastIdx] = el
end

local function nextDocument(el)
    if tmp.dayForecast.day == nil or tmp.dayForecast.day ~= el.day then
        if tmp.dayForecast.day then
            calculateDateRange(tmp.dayForecast)
            if tmp.dayForecastIdx == owe_p.forecastDays then
                onDataEnd()
                return false
            end
            tmp.dayForecastIdx = tmp.dayForecastIdx + 1
        end
        tmp.dayForecast.day = el.day
        tmp.dayForecast.el = {}
    end
    table.insert(tmp.dayForecast.el, el)
    return true
end

local function acceptTime(date)
    local hourStr = date:sub(12, 13)
    local hour = tonumber(hourStr)
    return hour >= 6 and hour <= 21
end

function owe_p.onNextDocument(doc)
    if tmp.dayForecastIdx == owe_p.forecastDays + 1 then
        return
    end
    if not doc.dt_txt then return end
    local date = doc.dt_txt
    if not acceptTime(date) then
        return
    end

    local val = {}
    val.date = date
    val.day = date:sub(6, 10)
    val.tempMin = doc.main.temp_min
    val.tempMax = doc.main.temp_max
    val.temp = doc.main.temp
    local dw = doc.weather[1]
    val.description = dw.description
    val.id = dw.id
    nextDocument(val)
end