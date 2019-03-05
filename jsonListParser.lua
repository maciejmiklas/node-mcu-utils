require "json"
require "log"
JsonListParserFactory = {}

local jlp = {
    elementReadyCallback = nil,
    listElementName = "list",
    listFound = false,
    tmp = nil,
    keepReading = true
}

local mt = { __index = jlp }
function JsonListParserFactory:create()
    local obj = {}
    setmetatable(obj, mt)
    return obj
end

function jlp:registerElementReady(callback)
    self.elementReadyCallback = callback
end

function jlp:reset()
    self.listFound = false
    self.tmp = nil
    self.keepReading = true
end

function jlp:onNextChunk(data)
    if not self.keepReading then return end
    local dataIdx = 1
    if not self.listFound then
        local listIdx = string.find(data, self.listElementName)
        if listIdx == -1 then
            return
        else
            dataIdx = listIdx
            self.listFound = true
        end
    elseif self.tmp then
        data = self.tmp .. data
    end
    self.tmp = nil

    local lBracketIdx = -1
    local lBracketCnt = 0
    local rBracketCnt = 0
    local dataLen = string.len(data)
    local lastDocEnd = -1
    for idx = dataIdx, dataLen, 1 do
        local chr = data:sub(idx, idx)
        if chr == "{" then
            if lBracketCnt == 0 then
                lBracketIdx = idx
            end
            lBracketCnt = lBracketCnt + 1

        elseif chr == "}" then
            rBracketCnt = rBracketCnt + 1
        end

        if lBracketCnt > 0 and rBracketCnt > 0 and lBracketCnt == rBracketCnt then
            local docTxt = data:sub(lBracketIdx, idx)
            local jobj = json.decode(docTxt)
            self.keepReading = self.elementReadyCallback(jobj)
            if not self.keepReading then
                self.reset()
                return
            end
            lBracketIdx = -1
            lBracketCnt = 0
            rBracketCnt = 0
            lastDocEnd = idx
        end
    end

    if lBracketCnt ~= rBracketCnt then
        local dataStart = dataIdx
        if lastDocEnd ~= -1 then
            dataStart = lastDocEnd + 1
        end
        self.tmp = data:sub(dataStart, dataLen) data:sub(1, 10)
    end
end