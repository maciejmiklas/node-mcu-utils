--TODO change log level over uart 0
log = {
    is_debug = false,
    is_info = true,
    is_warn = true,
    is_error = true,
    uart_id = 0
}

local function ln(pref, arg)
    uart.write(log.uart_id, pref)
    for _, msg in ipairs(arg) do
        uart.write(log.uart_id, tostring(msg))
    end
    uart.write(log.uart_id, "\n")
end

function log.debug(...)
    if log.is_debug then
        ln("#D ", arg)
    end
end

function log.info(...)
    if log.is_info then
        ln("#I ", arg)
    end
end

function log.error(...)
    if log.is_error then
        ln("#E ", arg)
    end
end

function log.warn(...)
    if log.is_warn then
        ln("#W ", arg)
    end
end

function log.setup(debug, info, warn, error)
    ln("LOG->", { "D:", debug, " I:", info, " W:", warn, " E:", error })
    log.is_debug = debug
    log.is_info = info
    log.is_warn = warn
    log.is_error = error

    if debug then
        node.stripdebug(1)
        node.osprint(true)

    elseif info then
        node.stripdebug(2)
        node.osprint(true)

    else
        node.stripdebug(3)
        node.osprint(false)
    end
end