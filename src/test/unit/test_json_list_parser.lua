require "json_list_parser"

local found_cnt = 1
local expected_data_a = {
    { "2019-01-29 18:00:00", -2.05 },
    { "2019-01-29 21:00:00", -2.27 },
    { "2019-01-30 00:00:00", -3.64 },
    { "2019-01-30 03:00:00", -5.3 },
    { "2019-01-30 06:00:00", -5.7 },
    { "2019-01-30 09:00:00", -3.75 },
    { "2019-01-30 12:00:00", -1.27 },
    { "2019-01-30 15:00:00", -1 },
    { "2019-01-30 18:00:00", -1.89 },
    { "2019-01-30 21:00:00", -2.32 },
    { "2019-01-31 00:00:00", -3.38 },
    { "2019-01-31 03:00:00", -5.03 },
    { "2019-01-31 06:00:00", -6.58 },
    { "2019-01-31 09:00:00", -3.51 },
    { "2019-01-31 12:00:00", 1 },
    { "2019-01-31 15:00:00", 0.58 },
    { "2019-01-31 18:00:00", -3.8 },
    { "2019-01-31 21:00:00", -6.02 },
    { "2019-02-01 00:00:00", -6.52 },
    { "2019-02-01 03:00:00", -7.47 },
    { "2019-02-01 06:00:00", -7.26 },
    { "2019-02-01 09:00:00", -3.44 },
    { "2019-02-01 12:00:00", 2.42 },
    { "2019-02-01 15:00:00", 3.43 },
    { "2019-02-01 18:00:00", 1.14 },
    { "2019-02-01 21:00:00", 2.21 },
    { "2019-02-02 00:00:00", 3.68 },
    { "2019-02-02 03:00:00", 4.72 },
    { "2019-02-02 06:00:00", 5.65 },
    { "2019-02-02 09:00:00", 8.11 },
    { "2019-02-02 12:00:00", 9.12 },
    { "2019-02-02 15:00:00", 8.8 },
    { "2019-02-02 18:00:00", 7.37 },
    { "2019-02-02 21:00:00", 4.26 },
    { "2019-02-03 00:00:00", 1.43 },
    { "2019-02-03 03:00:00", 0.78 },
    { "2019-02-03 06:00:00", 1.32 },
    { "2019-02-03 09:00:00", 2.69 },
    { "2019-02-03 12:00:00", 5.1 },
    { "2019-02-03 15:00:00", 4.05 }
}

local testCnt = 0;


local function read_file(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

local function porcess_weather_part_a(doc)
    if not doc.dt_txt then return end
    local ev = expected_data_a[found_cnt]
    found_cnt = found_cnt + 1

    assert(doc.dt_txt == ev[1], "Error on " .. found_cnt .. " - " .. ev[1])
    assert(doc.main.temp == ev[2], "Error on " .. found_cnt .. " - " .. ev[2])
end

local function porcess_weather_part_b(doc)
    if not doc.dt_txt then return end
    local ev = expected_data_a[found_cnt]
    found_cnt = found_cnt + 1
end

local function test_parse_whole_document_at_once()
    found_cnt = 1
    testCnt = testCnt + 1
    local data = read_file("test/unit/data/weather.json")
    local jp = JsonListParser.new()
    jp:register_element_ready(porcess_weather_part_a)
    jp:on_next_chunk(data)

    assert(found_cnt == 41, "Found only: " .. found_cnt)
end

local function test_parse_chunks_a()
    found_cnt = 1
    testCnt = testCnt + 1
    local jp = JsonListParser.new()
    jp:register_element_ready(porcess_weather_part_a)
    jp:on_next_chunk(read_file("test/unit/data/weather_a_001.json"))
    jp:on_next_chunk(read_file("test/unit/data/weather_a_002.json"))
    jp:on_next_chunk(read_file("test/unit/data/weather_a_003.json"))
    jp:on_next_chunk(read_file("test/unit/data/weather_a_004.json"))
    jp:on_next_chunk(read_file("test/unit/data/weather_a_005.json"))
    jp:on_next_chunk(read_file("test/unit/data/weather_a_006.json"))
    jp:on_next_chunk(read_file("test/unit/data/weather_a_007.json"))

    assert(found_cnt == 41, "Found only: " .. found_cnt)
end

local function test_parse_chunks_b()
    found_cnt = 1
    testCnt = testCnt + 1
    local jp = JsonListParser.new()
    jp:register_element_ready(porcess_weather_part_b)
    jp:on_next_chunk(read_file("test/unit/data/weather_b_001.json"))
    jp:on_next_chunk(read_file("test/unit/data/weather_b_002.json"))
    jp:on_next_chunk(read_file("test/unit/data/weather_b_003.json"))
    jp:on_next_chunk(read_file("test/unit/data/weather_b_004.json"))
    jp:on_next_chunk(read_file("test/unit/data/weather_b_005.json"))
    jp:on_next_chunk(read_file("test/unit/data/weather_b_006.json"))
    jp:on_next_chunk(read_file("test/unit/data/weather_b_007.json"))
    jp:on_next_chunk(read_file("test/unit/data/weather_b_008.json"))
    jp:on_next_chunk(read_file("test/unit/data/weather_b_009.json"))

    assert(found_cnt == 37, "Found only: " .. found_cnt)
end

test_parse_whole_document_at_once()
test_parse_chunks_a()
test_parse_chunks_b()
print("Done - Executed " .. testCnt .. " tests, all OK")