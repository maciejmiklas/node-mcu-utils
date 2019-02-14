require "jsonListParser"

-- parser api
owe_p = {}

-- forecast by day
local tmp = {}

-- forecast by a half day
owe_fm = {}

-- forecast as text for arduino
owe_atx = "EMPTY"

function owe_p.onDataStart()
    owe_fm = {}
end

function owe_p.onDataEnd()
    --    for date, weather in pairs(owe_fd) do
    --        print(">>" .. date)
    --    end
end

local function calculateDateRange(data)
    local el = {}
    el.tempMin = 0
    el.tempMax = 0
    el.description = {}

    owe_fm[data.day] = el
    local cnt = 0
    for _, weather in pairs(data.el) do
        cnt = cnt + 1
        el.tempMin = el.tempMin + weather.tempMin
        el.tempMax = el.tempMax + weather.tempMax
        table.insert(el.description, weather.description)
    end
    el.tempMin = el.tempMin / cnt
    el.tempMax = el.tempMax / cnt
    print("A")
end

local function onDataEl(el)
    local day = el.date:sub(1, el.date:find(" ") - 1)
    if tmp.day == nil or tmp.day ~= day then
        if tmp.day then
            calculateDateRange(tmp)
        end
        tmp.day = day
        tmp.el = {}
    end
    table.insert(tmp.el, el)
end

function owe_p.onData(doc)
    if not doc.dt_txt then return end
    local date = doc.dt_txt
    local val = {}
    val.date = date
    val.tempMin = doc.main.temp_min
    val.tempMax = doc.main.temp_max
    val.temp = doc.main.temp
    local dw = doc.weather[1]
    val.description = dw.description
    val.id = dw.id
    onDataEl(val)
end




--   local day = date:sub(1, date:find(" ") - 1)

--  if owedf[date] == nil then
