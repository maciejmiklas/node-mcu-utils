require "sjson"
require "log"

JsonListParser = {
    element_ready_callback = nil,
    list_element_name = "list",
    list_found = false,
    tmp = nil,
    keep_reading = true
}

function JsonListParser.new()
    return setmetatable({}, { __index = JsonListParser })
end

function JsonListParser:register_element_ready(callback)
    self.element_ready_callback = callback
end

function JsonListParser:reset()
    self.list_found = false
    self.tmp = nil
    self.keep_reading = true
end

function JsonListParser:on_next_chunk(data)
    if not self.keep_reading then return false end
    local data_idx = 1
    if not self.list_found then
        local list_idx = string.find(data, self.list_element_name)
        if list_idx == nil or list_idx == -1 then
            return true
        else
            data_idx = list_idx
            self.list_found = true
        end
    elseif self.tmp then
        data = self.tmp .. data
    end
    self.tmp = nil

    local l_bracket_idx = -1
    local l_bracket_cnt = 0
    local r_bracket_cnt = 0
    local data_len = string.len(data)
    local last_doc_end = -1
    for idx = data_idx, data_len, 1 do
        local chr = data:sub(idx, idx)
        if chr == "{" then
            if l_bracket_cnt == 0 then
                l_bracket_idx = idx
            end
            l_bracket_cnt = l_bracket_cnt + 1

        elseif chr == "}" then
            r_bracket_cnt = r_bracket_cnt + 1
        end

        if l_bracket_cnt > 0 and r_bracket_cnt > 0 and l_bracket_cnt == r_bracket_cnt then
            local docTxt = data:sub(l_bracket_idx, idx)
            local jobj = sjson.decode(docTxt)
            self.keep_reading = self.element_ready_callback(jobj)
            if not self.keep_reading then
                self:reset()
                return false
            end
            l_bracket_idx = -1
            l_bracket_cnt = 0
            r_bracket_cnt = 0
            last_doc_end = idx
        end
    end

    if l_bracket_cnt ~= r_bracket_cnt then
        local data_start = data_idx
        if last_doc_end ~= -1 then
            data_start = last_doc_end + 1
        end
        self.tmp = data:sub(data_start, data_len) data:sub(1, 10)
    end
    return true
end