-- Parser.lua
-- Modul untuk mengekstrak kode foto dari teks mentah

local Parser = {}

-- Helper to pad numbers with zeros
local function padNumber(numStr, targetLength)
    local len = string.len(numStr)
    if len < targetLength then
        return string.rep("0", targetLength - len) .. numStr
    end
    return numStr
end

-- Helper untuk trim whitespace
local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

-- Fungsi utama parse
function Parser.parse(rawText)
    if not rawText or rawText == "" then return {} end

    local results = {}
    local seen = {} -- untuk deduplikasi

    local function addResult(code)
        if code and code ~= "" and not seen[code] then
            table.insert(results, code)
            seen[code] = true
        end
    end

    -- 0. Pre-processing: Hapus ekstensi file umum agar tidak mengganggu parsing
    -- Misalnya file bernama "REV00003 2.JPG", jika tidak dihapus, " 2.JPG" bisa memicu deteksi angka "2"
    local processedText = rawText
    processedText = processedText:gsub("%.[jJ][pP][eE]?[gG]%s*", " ")
    processedText = processedText:gsub("%.[pP][nN][gG]%s*", " ")
    processedText = processedText:gsub("%.[aA][rR][wW]%s*", " ")
    processedText = processedText:gsub("%.[cC][rR]2%s*", " ")
    processedText = processedText:gsub("%.[nN][eE][fF]%s*", " ")
    processedText = processedText:gsub("%.[dD][nN][gG]%s*", " ")
    processedText = processedText:gsub("%.[rR][aA][wW]%s*", " ")

    -- 1. Pass 1: Deteksi Range (e.g., 0022 - 0025 atau DSC_0022 - DSC_0025)
    -- Kita buat iterasi while untuk mengurai string jika ada range, lalu kita hilangkan dari rawText agar tidak diparse ganda
    -- (menggunakan processedText yang sudah dibersihkan dari ekstensi)
    
    -- Tangkap pola range: [optional_prefix]angka - [optional_prefix]angka
    -- Lua pattern tidak se-powerful regex, jadi kita cari angka berdekatan dengan '-' atau '–'
    local rangePattern = "(%d+)%s*[-–]%s*(%d+)"
    for startStr, endStr in processedText:gmatch(rangePattern) do
        local startNum = tonumber(startStr)
        local endNum = tonumber(endStr)
        
        if startNum and endNum and startNum <= endNum and (endNum - startNum < 1000) then -- limit range untuk menghindari freeze
            local targetLen = string.len(startStr) -- gunakan panjang string awal untuk padding
            for i = startNum, endNum do
                addResult(padNumber(tostring(i), targetLen))
            end
        end
    end
    
    -- Hapus pola range dari teks agar tidak diproses sebagai angka individual
    processedText = processedText:gsub(rangePattern, " ")

    -- 2. Pass 2: Deteksi Prefixed Codes (e.g., DSC_0012, IMG_1234, _MG_123)
    -- Asumsi prefix mengandung huruf, underscore, atau hyphen
    for prefix, number in processedText:gmatch("([A-Za-z_%-]+)(%d+)") do
        -- Pastikan bukan bagian dari kata biasa (misal "tahun2023"), kita ambil prefix umum atau yang underscore/hyphen
        local cleanPrefix = prefix:match("([A-Za-z]+[_%-])")
        if cleanPrefix then
            addResult(cleanPrefix .. number)
        else
            -- Jika prefix nempel (seperti DSC0012), kita tambahkan aja karena spesifik
            -- Namun untuk aman, tambahkan angka dan prefix-nya
            addResult(prefix .. number)
        end
    end
    
    -- Hapus prefixed codes agar tidak terambil angkanya saja
    processedText = processedText:gsub("[A-Za-z_%-]+%d+", " ")

    -- 3. Pass 3: Deteksi Standalone Numbers (minimal 2 digit untuk menghindari noise seperti "bang", "1", "2")
    for numberStr in processedText:gmatch("(%d{2,})") do
         -- gmatch "%d{2,}" tidak didukung native Lua pattern, kita gunakan trik:
    end
    
    -- Trik Lua Pattern untuk minimal N karakter (contoh: %d%d+ untuk min 2 digit)
    for numberStr in processedText:gmatch("%d%d+") do
        addResult(numberStr)
    end
    
    -- Juga tangkap 1 digit jika benar-benar berdiri sendiri (dibatasi oleh space/koma)
    for numberStr in processedText:gmatch("%s(%d)[%s,%p]") do
        addResult(numberStr)
    end
    -- Tangkap di awal string
    for numberStr in processedText:gmatch("^(%d)[%s,%p]") do
        addResult(numberStr)
    end
    -- Tangkap di akhir string
    for numberStr in processedText:gmatch("[%s,%p](%d)$") do
        addResult(numberStr)
    end

    return results
end

return Parser
