log = {}

function log.info(...)
    local msg = ""
    for i, v in ipairs(arg) do
        msg = msg .. tostring(v)
    end

    print("#### " .. msg)
end

function log.err(...)
    local msg = ""
    for i, v in ipairs(arg) do
        msg = msg .. tostring(v)
    end

    print("##ERR## " .. msg)
end

function log.warn(...)
    local msg = ""
    for i, v in ipairs(arg) do
        msg = msg .. tostring(v)
    end

    print("##WARN## " .. msg)
end