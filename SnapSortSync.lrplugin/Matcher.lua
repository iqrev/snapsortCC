-- Matcher.lua
-- Modul untuk mencocokkan kode hasil parsing dengan foto di katalog

local Matcher = {}

-- Helper fungsi untuk mengecek apakah string berakhir dengan pola tertentu
local function endsWith(str, ending)
    return ending == "" or str:sub(-string.len(ending)) == ending
end

-- Helper fungsi untuk mengekstrak angka dari akhir baseName (untuk perbandingan angka)
local function extractNumberAtEnd(str)
    -- Ambil urutan angka di akhir string (sebelum spasi/karakter lain jika ada)
    local numStr = str:match("(%d+)$")
    if numStr then
        return numStr
    end
    return nil
end

-- Main function untuk matching
-- catalog: objek LrCatalog
-- photos: array dari LrPhoto (hasil dari catalog:getTargetPhotos())
-- codes: array of string (hasil dari Parser.parse)
function Matcher.match(photos, codes)
    local matchedPhotos = {}
    local notFoundCodes = {}
    
    -- Buat lookup untuk mempercepat pencarian (BaseName -> Photo)
    -- Perlu diingat bahwa baseName bisa tidak unik, tapi kita petakan ke list photo
    local baseNameLookup = {}
    for _, photo in ipairs(photos) do
        -- Kita gunakan photo:getFormattedMetadata('fileName') dan hapus extension
        local fileName = photo:getFormattedMetadata('fileName')
        if fileName then
            -- Ekstrak baseName (hilangkan ekstensi seperti .CR2, .JPG, dll)
            local baseName = fileName:match("(.+)%..+") or fileName
            
            -- Simpan ke lookup (case insensitive mapping)
            local lowerBaseName = string.lower(baseName)
            if not baseNameLookup[lowerBaseName] then
                baseNameLookup[lowerBaseName] = {}
            end
            table.insert(baseNameLookup[lowerBaseName], { photo = photo, originalBaseName = baseName })
        end
    end

    -- Loop setiap kode dari user
    for _, code in ipairs(codes) do
        local lowerCode = string.lower(code)
        local found = false
        
        -- 1. Exact Match Cepat
        if baseNameLookup[lowerCode] then
            for _, item in ipairs(baseNameLookup[lowerCode]) do
                table.insert(matchedPhotos, item.photo)
                found = true
            end
        end
        
                -- 2. Jika tidak exact match, lakukan iterasi untuk Number Match dan Suffix Match
        if not found then
            for lowerBaseName, items in pairs(baseNameLookup) do
                local baseNumStr = extractNumberAtEnd(lowerBaseName)
                local codeNumStr = extractNumberAtEnd(lowerCode)
                
                -- Jika code dan baseName berakhiran angka, lakukan perbandingan numerik cerdas
                if baseNumStr and codeNumStr then
                    local bNum = tonumber(baseNumStr)
                    local cNum = tonumber(codeNumStr)
                    
                    -- Pastikan angkanya sama persis nilainya (contoh: 0012 == 12)
                    if bNum == cNum then
                        -- Cek apakah prefix dari code cocok dengan prefix baseName
                        local basePrefix = lowerBaseName:sub(1, -string.len(baseNumStr) - 1)
                        local codePrefix = lowerCode:sub(1, -string.len(codeNumStr) - 1)
                        
                        local cleanBasePrefix = basePrefix:gsub("[%s%-_]", "")
                        local cleanCodePrefix = codePrefix:gsub("[%s%-_]", "")
                        
                        -- Match jika prefix sama ATAU code tidak memiliki prefix (hanya angka)
                        if cleanBasePrefix == cleanCodePrefix or cleanCodePrefix == "" then
                            for _, item in ipairs(items) do
                                table.insert(matchedPhotos, item.photo)
                                found = true
                            end
                        end
                    end
                -- Jika bukan perbandingan angka murni, fallback ke suffix match biasa (misal code berupa huruf semua)
                elseif endsWith(lowerBaseName, lowerCode) then
                    -- Cek bahwa karakter sebelum suffix bukanlah alphanumeric (untuk mencegah partial match kata)
                    local prefixLen = string.len(lowerBaseName) - string.len(lowerCode)
                    if prefixLen == 0 or not lowerBaseName:sub(prefixLen, prefixLen):match("[%w]") then
                        for _, item in ipairs(items) do
                            table.insert(matchedPhotos, item.photo)
                            found = true
                        end
                    end
                end
                
                -- Jika sudah ketemu, kita tidak break karena bisa saja ada duplikat baseName (virtual copy, beda folder di scope)
            end
        end
        
        if not found then
            table.insert(notFoundCodes, code)
        end
    end
    
    -- Hapus duplikat di matchedPhotos (jika 1 foto match dengan beberapa kode entah kenapa)
    local uniqueMatched = {}
    local seenPhotos = {}
    for _, photo in ipairs(matchedPhotos) do
        -- Kita pakai localIdentifier sebagai key unik photo
        local id = photo.localIdentifier
        if not seenPhotos[id] then
            seenPhotos[id] = true
            table.insert(uniqueMatched, photo)
        end
    end

    return uniqueMatched, notFoundCodes
end

return Matcher
