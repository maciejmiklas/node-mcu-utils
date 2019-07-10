require "log"

wlan = {
    ssid = "SSID not set",
    max_queue_size = 4
}

local online = false
local callback_queue = {}
local off_reason = nil

local function on_online(ev, info)
    online = true
    off_reason = nil
    if log.is_info then
        log.info("WLAN ON:", info.ip, "/", info.netmask, ",gw:", info.gw)
    end

    -- execute callback waitnitg in queue
    local clb = table.remove(callback_queue)
    while clb ~= nil do
        local _, err = pcall(clb)
        if err ~= nil then
            if log.is_error then
                log.error(err)
            end
        end
        clb = table.remove(callback_queue)
    end
end

local function on_offline(ev, info)
    online = false
    if info.reason ~= off_reason then
        log.warn("Wlan OFF:", info.reason)
        off_reason = info.reason
    end
end

function wlan.setup(ssid, password)
    wifi.sta.on("disconnected", on_offline)
    wifi.sta.on("got_ip", on_online)

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
        if err ~= nil then
            if log.is_error then
                log.error(err)
            end
        end
        return
    end
    if table.getn(callback_queue) < wlan.max_queue_size then
        table.insert(callback_queue, callback)
    else
        if log.is_warn then log.warn("WLAN queue full") end
    end
end