uart_id = 2

local function on_data(data)
    print("IN: ", tostring(data))
end

local function on_error(data)
    print("ERR: ", tostring(data))
end

local cnt = 0;
local function on_timer()
    print(". "..cnt)
    cnt = cnt + 1
    uart.write(uart_id, "# " .. cnt .. "\n")
end

local tmrObj = tmr.create()
tmrObj:register(5000, tmr.ALARM_AUTO, on_timer)
tmrObj:start()

uart.setup(uart_id, 115200, 8, uart.PARITY_NONE, uart.STOPBITS_1, {rx = 16, tx = 17})
uart.on(uart_id, "data", '\r', on_data)
uart.on(uart_id, "error", on_error)
uart.setmode(uart_id, uart.MODE_UART)
uart.start(uart_id)