require "log"

wlan = {ssid="SSID not set", timerId = 0}

local online = false
local callbacks = {}
local offReason = nil

local function onOnline(ev, info)
  online = true
  offReason = nil
  log.info("Wlan ON:", info.ip, "/", info.netmask, ",gw:", info.gw)

  -- execute callback waitnitg in queue
  local clb = table.remove(callbacks)
  while clb ~= nil do
    local _, err = pcall(clb)
    if err ~= nil then log.err(err) end
    clb = table.remove(callbacks)
  end
end

local function onOffline(ev, info)
  online = false
  if info.reason ~= offReason then
    log.err("Wlan OFF:", info.reason)
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
    if err ~= nil then log.err(err) end
    return
  end

  table.insert(callbacks, callback)
end
