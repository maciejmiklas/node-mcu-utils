require "log"

sapi = {
    uratId = 1,
    baud = 115200,
    pins = { tx = 17, rx = 16 }
}
scmd = {}

function sapi.sendError()
    uart.write(sapi.uratId, "ER\n")
end

function sapi.sendOK()
    uart.write(sapi.uratId, "OK\n")
end

local function onError(data)
    log.error("UART Error:" .. data)
end

local function onData(data)
    if data == nil then return end

    local dataLen = string.len(data);
    if log.isDebug then log.debug("RX: '" .. data .. "' " .. dataLen) end
    if dataLen < 5 then return end

    local status, err
    -- static command has 3 characters + \t\n
    if dataLen == 5 then
        local cmd = string.sub(data, 1, 3)
        status, err = pcall(scmd[cmd])

        -- dynamic command has folowwing format: [3 chars command][space][param]
    else
        local cmd = string.sub(data, 1, 3)
        local param = string.sub(data, 4, dataLen):gsub('%W', '')
        status, err = pcall(scmd[cmd], param)
    end

    if status ~= true then uart.write(sapi.uratId, "ERR:" .. err .. '\n') end
end

function sapi.start()
    uart.setup(sapi.uratId, sapi.baud, 8, uart.PARITY_NONE, uart.STOPBITS_1, sapi.pins)
    uart.on(sapi.uratId, "data", '\n', onData, 0)
    uart.on(sapi.uratId, "error", onError)
    uart.start(sapi.uratId)

    if log.isInfo then log.info("UART: " .. tostring(sapi)) end
    -- scheduler.register(function() uart.write(sapi.uratId, "Hi UART!\n") end, "Hi UART", 1, 1)
end


