require "dateformatEurope";
require "credentials"
require "serialAPI"
require "serialAPIClock"
require "serialAPIOpenWeather"
require "blink"
require "scheduler"

node.stripdebug(3)
node.osprint(false)

function scmd.GFR()
    collectgarbage()
    uart.write(sapi.uratId, "RAM: " .. (node.heap() / 1000))
end

local change = {
    lastWeatherSyncSec = -1,
    ntpcStat = nil,
    oweStat = nil,
    text = "",
    updateCount = 0,
    lastGTUCall = -1
}

-- return short status for all modules.
function scmd.GSS()
    local ntpcStat = ntpc.status()
    local oweStat = owe_net.status()
    local status = ""
    if ntpcStat == nil and oweStat == nil then
        status = "OK"
    else
        if ntpcStat ~= nil then
            status = status .. ntpcStat .. " "
        end
        if oweStat ~= nil then
            status = status .. oweStat
        end
        status = status .. "; RAM:" .. (node.heap() / 1000) .. "kb"
    end
    uart.write(sapi.uratId, status)
end

-- return 1 if the text has been changed since last call, otherwise 0
function scmd.GTC()
    local changed = "1"
    if change.lastGTUCall == change.updateCount then
        changed = "0"
    end
    change.lastGTUCall = change.updateCount
    uart.write(sapi.uratId, changed)
end

-- scrolling text for arduino
function scmd.GTX()
    uart.write(sapi.uratId, change.text)
end

local function generateWeatherText(ntpcStat, oweStat)
    local text = "Initializing.....       "
    if ntpcStat == nil and oweStat == nil then
        text = owe_p.forecastText
    else
        collectgarbage()
        if owe_p.forecastText ~= nil and owe_p.forecastText:len() > 0 then
            text = owe_p.forecastText .. " >> "
        end

        if oweStat ~= nil then
            text = text .. oweStat
        end
        if ntpcStat ~= nil then
            text = " " .. text .. " " .. ntpcStat
        end
    end
    text = text .. " >> RAM:" .. (node.heap() / 1000) .. "kb"
    text = text .. "          "
    return text
end

local function updateWehaterText()
    local ntpcStat = ntpc.status()
    local oweStat = owe_net.status()
    local lastWeatherSyncSec = owe_net.lastSyncSec

    if change.lastWeatherSyncSec == lastWeatherSyncSec and change.ntpcStat == ntpcStat and change.oweStat == oweStat then
        return
    end
    if log.isInfo then log.info("Update weather text") end

    change.lastWeatherSyncSec = lastWeatherSyncSec
    change.ntpcStat = ntpcStat
    change.oweStat = oweStat
    change.text = generateWeatherText(ntpcStat, oweStat)
    change.updateCount = change.updateCount + 1
end

local function printRAM()
    collectgarbage()
    print("RAM: " .. (node.heap() / 1000))
end

scheduler.register(updateWehaterText, "UpdateWehaterText", 1, 1)
scheduler.register(printRAM,"printRAM", 60, 60)


wlan.setup(cred.ssid, cred.password)
sapi.start()
ntpc.start("pool.ntp.org")
owe_net.start()
blink.start()
scheduler.start()