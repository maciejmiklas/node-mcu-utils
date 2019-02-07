JsonListParserFactory = {}

local jlp = {
    elementReadyCallback = nil,
    listElementName = "list",
    listFound = false,
    tmp = nil,
    decoder = nil
}

local mt = { __index = jlp }
function JsonListParserFactory:create()
    local obj = {}
    setmetatable(obj, mt)
    obj.decoder = sjson.decoder()
    return obj
end

function jlp:onElementReady(callback)
    self.elementReadyCallback = callback
end

function jlp:data(data)
    local dataIdx = 1
    local dataSize = string.len(data)
    if not self.listFound then
        local listIdx = string.find(data, self.listElementName)
        if listIdx == -1 then
            return
        else
            dataIdx = listIdx
            self.listFound = true
        end
    end

    local listBeginIdx
    local listEndIdx

    while (dataIdx < dataSize) do
        listBeginIdx = string.find(data, "{", dataIdx)
        if listBeginIdx then
            dataIdx = listBeginIdx
        elseif not self.tmp then
            break
        end

        listEndIdx = string.find(data, "},%s*{", dataIdx)
        if listEndIdx then
            dataIdx = listEndIdx
        else
        end

        local listEl
        if self.tmp then
            local listEnd = string.sub(data, 1, listEndIdx)
            listEl = self.tmp .. listEnd
            self.tmp = nil
        else
            if listBeginIdx and not listEndIdx then
                self.tmp = string.sub(data, listBeginIdx, dataSize)
                break
            else
                listEl = string.sub(data, listBeginIdx, listEndIdx)
            end
        end
        print("DECODE: ", listEl)
        local jobj = self.decoder:decode(listEl)
        self.elementReadyCallback(jobj)
        print(listBeginIdx, " - ", listEndIdx, " - ", dataIdx, " - ", dataSize)
    end
end

