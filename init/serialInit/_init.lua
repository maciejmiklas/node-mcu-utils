require "credentials"
require "serialAPI"
require "serialAPIClock"
require "serialAPIOpenWeather"

node.stripdebug(3)
node.osprint(false)

function scmd.GFR()
    collectgarbage()
    uart.write(0, "RAM: " .. (node.heap() / 1000))
end

-- return short status for all modules.
function scmd.GSS()
    local ntpcStat = ntpc.status()
    local oweStat = owe_net.status()

    local status
    if ntpcStat == nil and oweStat == nil then
        status = "1"
    else
        status = "RAM:" .. (node.heap() / 1000) .. "kb"
        if ntpcStat ~= nil then
            status = status .. ntpcStat
        end
        if oweStat ~= nil then
            status = status .. " " .. oweStat
        end
    end
    uart.write(0, status)
end

-- scrolling text for arduino
function scmd.GTX()
    local ntpcStat = ntpc.status()
    local oweStat = owe_net.status()

    local text
    if ntpcStat == nil and oweStat == nil then
        text = owe_p.forecastText
    else
        if oweStat ~= nil then
            text = owe_p.forecastText .. "  ->  "
        else
            text = oweStat .. ", "
        end
        if ntpcStat ~= nil then
            text = text .. ntpcStat
        end
        text = text .. ", RAM:" .. (node.heap() / 1000) .. "kb      "
    end
    uart.write(0, text)
end

-- network connect
wlan.setup(cred.ssid, cred.password)

-- start serial API by enabling gpio and uart
sapi.start()

-- start NTP synchronization
ntpc.start("pool.ntp.org")

-- start weather with serial API
owe_net.start()
