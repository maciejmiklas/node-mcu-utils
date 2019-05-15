require "log"

sapi = {
    uart_id = 2,
    baud = 115200,
    pins = { rx = 16, tx = 17 }
}
scmd = {}

function sapi.send_error()
    uart.write(sapi.uart_id, "ER\n")
end

function sapi.send_ok()
    uart.write(sapi.uart_id, "OK\n")
end

function sapi.send(data)
    if log.is_debug then
        log.debug("SP->", data)
    end
    uart.write(sapi.uart_id, data .. '\n')
end

local function on_error(data)
    if log.is_error then
        log.error("SP:", data)
    end
end

local function on_data(data)
    if data == nil then
        return
    end
    local data_len = string.len(data);
    if data_len < 3 then
        if log.is_debug then
            log.debug("SP LEN ERR: '", data, "', Len:", data_len)
        end
        return
    end

    local status, err
    -- dynamic command has following format: [3 chars command][space][param]
    if string.sub(data, 4, 4) == ' ' then
        local cmd = string.sub(data, 1, 3)
        local param = string.sub(data, 4, data_len):gsub('%W', '')
        if log.is_debug then
            log.debug("SP<-(", data_len, ")-", cmd, "(", param, ")")
        end
        status, err = pcall(scmd[cmd], param)
    else
        -- static command has 3 characters + \t
        local cmd = string.sub(data, 1, 3)
        if log.is_debug then
            log.debug("SP<-(", data_len, ")-", cmd)
        end
        status, err = pcall(scmd[cmd])
    end

    if status ~= true then
        log.error(err)
        uart.write(sapi.uart_id, "ERR:" .. err .. '\n')
    end
end

function sapi.start()
    if sapi.uart_id == 0 then
        uart.setup(sapi.uart_id, sapi.baud, 8, uart.PARITY_NONE, uart.STOPBITS_1)
    else
        uart.setup(sapi.uart_id, sapi.baud, 8, uart.PARITY_NONE, uart.STOPBITS_1, sapi.pins)
    end
    uart.on(sapi.uart_id, "data", '\r', on_data)
    uart.on(sapi.uart_id, "error", on_error)
    uart.setmode(sapi.uart_id, uart.MODE_UART)
    uart.start(sapi.uart_id)
end