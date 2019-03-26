require "log"

sapi = {
    urat_id = 0,
    pins = {},

    --    urat_id = 1,
    --    pins = { tx = 17, rx = 16 },

    baud = 115200
}
scmd = {}

function sapi.send_error()
    uart.write(sapi.urat_id, "ER\n")
end

function sapi.send_ok()
    uart.write(sapi.urat_id, "OK\n")
end

local function on_error(data)
    if log.is_error then log.error("SP:", data) end
end

local function on_data(data)
    if data == nil then return end

    local data_len = string.len(data);
    if log.is_debug then log.debug("SP RX: '", data, "', Len:", data_len) end
    if data_len < 5 then return end

    local status, err
    -- static command has 3 characters + \t\n
    if data_len == 5 then
        local cmd = string.sub(data, 1, 3)
        if log.is_debug then log.debug("SP->", cmd) end
        status, err = pcall(scmd[cmd])

        -- dynamic command has folowwing format: [3 chars command][space][param]
    else
        local cmd = string.sub(data, 1, 3)
        local param = string.sub(data, 4, data_len):gsub('%W', '')
        if log.is_debug then log.debug("SP->", cmd, "(", param, ")") end
        status, err = pcall(scmd[cmd], param)
    end

    if status ~= true then uart.write(sapi.urat_id, "ERR:" .. err .. '\n') end
end

function sapi.start()
    uart.setup(sapi.urat_id, sapi.baud, 8, uart.PARITY_NONE, uart.STOPBITS_1, sapi.pins)
    uart.on(sapi.urat_id, "data", '\n', on_data, 0)
    uart.on(sapi.urat_id, "error", on_error)
    uart.start(sapi.urat_id)
end


