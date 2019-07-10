log = {
    is_debug = false,
    is_info = true,
    is_warn = true,
    is_error = true,
    uart_id = 0,
}

log_file = {
    enabled = true,
    file_name = "utils.log",
    max_lines = 10000
}

local line_cnt = 0
local file_ref = nil

local function open_file()
    file_ref = file.open(log_file.file_name, "a+")
end

local function ln_file(pref, arg)
    if not log_file.enabled then
        return
    end

    if file_ref == nil then
        open_file()
    end

    if line_cnt == log_file.max_lines then
        uart.write(log.uart_id, "#I LOG rotating file\n")
        file_ref.close();
        file.remove(log_file.file_name)
        open_file()
    end

    line_cnt = line_cnt +1

    file_ref.write("\n")
    file_ref.write(pref)
    for _, msg in ipairs(arg) do
        file_ref.write(tostring(msg))
    end

    file_ref.flush()
end

local function ln(pref, arg)
    uart.write(log.uart_id, pref)
    for _, msg in ipairs(arg) do
        uart.write(log.uart_id, tostring(msg))
    end
    uart.write(log.uart_id, "\n")

    ln_file(pref, arg)
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

function log.change_level(debug, info, warn, error)
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