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
        if ntpcStat ~= nil then
            status = status .. ntpcStat
        end
        if oweStat ~= nil then
            status = status .. " " .. oweStat
        end
        status = " RAM:" .. (node.heap() / 1000) .. "kb"
    end
    uart.write(0, status)
end

-- scrolling text for arduino
function scmd.GTX()
    local ntpcStat = ntpc.status()
    local oweStat = owe_net.status()

    local text = ""
    if ntpcStat == nil and oweStat == nil then
        text = owe_p.forecastText
    else
        collectgarbage()

        if owe_p.forecastText ~= nil then
            text = owe_p.forecastText .. " >> "
        end

        if oweStat ~= nil then
            text = text .. oweStat
        end
        if ntpcStat ~= nil then
            text = " " .. text " " .. ntpcStat
        end
    end
    text = text .. " >> RAM:" .. (node.heap() / 1000) .. "kb"
    text = text .. "          "
    uart.write(0, text)
end

scheduler.register(scmd.GFR, "GFR", 60, 60)

-- network connect
wlan.setup(cred.ssid, cred.password)

sapi.start()
ntpc.start("pool.ntp.org")
owe_net.start()
blink.start()
scheduler.start()