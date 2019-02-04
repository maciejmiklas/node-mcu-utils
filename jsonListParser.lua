local json = require("JSON")
JsonListParserFactory = {}

local function state_findList(self, data)
  local fidx = string.find(data, self.listElementName)
end

local jlp = {
  elementReadyCallback = nil,
  listElementName = "list",
  listFound = false,
  tmp = nil,
  decoder = nil
}

local mt = {__index = jlp}
function JsonListParserFactory:create()
  obj = {}
  setmetatable(obj, mt)
  --obj.decoder = sjson.decoder()
  obj.decoder = json  
  return obj
end

function jlp:onElementReady(callback)
  self.elementReadyCallback = callback
end

local function repeats(s,c)
  local _,n = s:gsub(c,"")
  return n
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

  local listBeginIdx = nil
  local listEndIdx = nil
  while (dataIdx < dataSize) do
    listBeginIdx = string.find(data, "{", dataIdx)
    if listBeginIdx then
      dataIdx = listBeginIdx
    elseif not tmp then
      break
    end

    listEndIdx = string.find(data, "},%s*{", dataIdx)
    if listEndIdx then
      dataIdx = listEndIdx
    else
    end

    local listEl = nil
    if tmp then
      local listEnd = string.sub(data, 1, listEndIdx)
      listEl = tmp..listEnd
      tmp = nil
    else
      if listBeginIdx and not listEndIdx then
        tmp = string.sub(data, listBeginIdx, dataSize)
        break
      else
        listEl = string.sub(data, listBeginIdx, listEndIdx)
      end
    end
    print("DECODE: ", listEl)
    local jobj = json:decode(listEl)
    self.elementReadyCallback(jobj)
    print (listBeginIdx, " - ", listEndIdx, " - ", dataIdx, " - ", dataSize)
  end
end

