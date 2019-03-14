require "log"

wlan = { ssid = "SSID not set" }

local online = false
local callbacks = {}
local offReason = nil

local function onOnline(ev, info)
    online = true
    offReason = nil
    if log.isInfo then log.info("Wlan ON:" .. info.ip .. "/" .. info.netmask .. ",gw:" .. info.gw) end

    -- execute callback waitnitg in queue
    local clb = table.remove(callbacks)
    while clb ~= nil do
        local _, err = pcall(clb)
        if err ~= nil then log.error(err) end
        clb = table.remove(callbacks)
    end
end

local function onOffline(ev, info)
    online = false
    if info.reason ~= offReason then
        log.warn("Wlan OFF:", info.reason)
        offReason = info.reason
    end
end

function wlan.setup(ssid, password)
    wifi.sta.on("disconnected", onOffline)
    wifi.sta.on("got_ip", onOnline)

    wlan.ssid = ssid
    wlan.pwd = password
    wifi.mode(wifi.STATION)
    wifi.start()
    wifi.sta.config(wlan)
end

-- this method can be executed multiple times. It will queue all callbacks untill it gets
-- WiFi connection
function wlan.execute(callback)
    if online then
        local _, err = pcall(callback)
        if err ~= nil then log.error(err) end
        return
    end

    table.insert(callbacks, callback)
end
