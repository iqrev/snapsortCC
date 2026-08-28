-- SnapSortSync.lua
-- Main orchestration and UI untuk SnapSort Sync Plugin

local LrDialogs = import 'LrDialogs'
local LrView = import 'LrView'
local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'
local LrBinding = import 'LrBinding'
local LrFunctionContext = import 'LrFunctionContext'
local LrColor = import 'LrColor'

local Parser = require 'Parser'
local Matcher = require 'Matcher'


-- Mapping nama warna untuk label UI ke value internal Lightroom
local colorOptions = {
    { title = "Red",    value = "red" },
    { title = "Yellow", value = "yellow" },
    { title = "Green",  value = "green" },
    { title = "Blue",   value = "blue" },
    { title = "Purple", value = "purple" },
}

local actionTypeOptions = {
    { title = "Color Label", value = "color" },
    { title = "Flag",        value = "flag" },
    { title = "Rating",      value = "rating" },
}

local flagOptions = {
    { title = "Flagged (Pick)", value = 1 },
    { title = "Unflagged",      value = 0 },
    { title = "Rejected",       value = -1 },
}

local ratingOptions = {
    { title = "1 Star",  value = 1 },
    { title = "2 Stars", value = 2 },
    { title = "3 Stars", value = 3 },
    { title = "4 Stars", value = 4 },
    { title = "5 Stars", value = 5 },
    { title = "0 Stars (None)", value = 0 },
}


-- Fungsi utama untuk menampilkan UI dan eksekusi
local function showDialog()
    LrFunctionContext.callWithContext("SnapSortSyncDialog", function(context)
        local f = LrView.osFactory()
        
        local props = LrBinding.makePropertyTable(context)
        
        -- Nilai default properti UI
        props.rawText = ""
        props.actionType = "color"
        props.selectedColor = "red"
        props.selectedFlag = 1
        props.selectedRating = 5
        props.previewText = "ℹ️ Preview: 0 kode terdeteksi"
        props.parsedCodes = {} -- Simpan hasil parse
        
        -- Observer untuk live preview
        props:addObserver('rawText', function()
            local codes = Parser.parse(props.rawText)
            props.parsedCodes = codes
            local count = #codes
            if count == 0 then
                props.previewText = "ℹ️ Preview: 0 kode terdeteksi"
            else
                -- Tampilkan preview (maksimal 10 kode pertama)
                local displayCodes = {}
                for i = 1, math.min(count, 10) do
                    table.insert(displayCodes, codes[i])
                end
                
                local previewStr = table.concat(displayCodes, ", ")
                if count > 10 then
                    previewStr = previewStr .. " ... (+" .. (count - 10) .. " lainnya)"
                end
                
                props.previewText = string.format("ℹ️ Preview: %d kode terdeteksi\n%s", count, previewStr)
            end
        end)
        
        -- Buat komponen UI
        local dialogContent = f:column {
            spacing = f:control_spacing(),
            bind_to_object = props,
            
            f:static_text {
                title = "Daftar Kode Foto dari Klien:",
                font = "<system/bold>",
            },
            
            f:edit_field {
                value = LrView.bind('rawText'),
                width_in_chars = 50,
                height_in_lines = 10,
                allows_newlines = true,
                tooltip = "Paste teks mentah klien di sini.\nContoh: 'DSC_0012, 0015, 0022 - 0025'",
            },
            
            f:row {
                spacing = f:label_spacing(),
                f:static_text { title = "Aksi / Tagging:", width = LrView.share "labelWidth" },
                f:popup_menu {
                    value = LrView.bind('actionType'),
                    items = actionTypeOptions,
                },
            },
            
            f:row {
                spacing = f:label_spacing(),
                f:static_text { title = "Nilai:", width = LrView.share "labelWidth" },
                f:view {
                    place = "overlapping",
                    f:popup_menu {
                        value = LrView.bind('selectedColor'),
                        items = colorOptions,
                        visible = LrView.bind {
                            key = 'actionType',
                            transform = function(v) return v == 'color' end,
                        },
                    },
                    f:popup_menu {
                        value = LrView.bind('selectedFlag'),
                        items = flagOptions,
                        visible = LrView.bind {
                            key = 'actionType',
                            transform = function(v) return v == 'flag' end,
                        },
                    },
                    f:popup_menu {
                        value = LrView.bind('selectedRating'),
                        items = ratingOptions,
                        visible = LrView.bind {
                            key = 'actionType',
                            transform = function(v) return v == 'rating' end,
                        },
                    },
                }
            },
            
            f:separator { fill_horizontal = 1 },
            
            f:static_text {
                title = "Scope: Plugin akan mencari di folder/collection yang sedang aktif.\nUntuk membatasi, seleksi foto tertentu sebelum menjalankan plugin.",
                height_in_lines = 2,
                font = "<system/small>",
                text_color = LrColor(0.5, 0.5, 0.5),
            },
            
            f:static_text {
                title = LrView.bind('previewText'),
                height_in_lines = 2,
                fill_horizontal = 1,
            }
        }
        
        -- Tampilkan dialog
        local result = LrDialogs.presentModalDialog {
            title = "SnapSort Sync - Tandai Foto",
            contents = dialogContent,
            actionVerb = "Tandai Foto",
            cancelVerb = "Batal",
        }
        
        -- Jika user klik "Tandai Foto"
        if result == 'ok' then
            local catalog = LrApplication.activeCatalog()
            local codes = props.parsedCodes
            
            if #codes == 0 then
                LrDialogs.message("Peringatan", "Tidak ada kode foto yang terdeteksi dari teks Anda.", "warning")
                return
            end
            
            -- Ambil foto dari folder/collection yang sedang aktif
            -- getTargetPhotos() otomatis mengembalikan:
            --   - Foto yang diseleksi (jika ada seleksi)
            --   - Semua foto di folder/collection aktif (jika tidak ada seleksi)
            local targetPhotos = catalog:getTargetPhotos()
            
            if #targetPhotos == 0 then
                LrDialogs.message("Peringatan", "Tidak ada foto di folder/collection yang sedang aktif.", "warning")
                return
            end
            
            -- Cocokkan foto
            local matchedPhotos, notFoundCodes = Matcher.match(targetPhotos, codes)
            
            if #matchedPhotos == 0 then
                LrDialogs.message("Hasil", "Tidak ada foto yang cocok ditemukan di katalog untuk kode yang diberikan.", "warning")
                return
            end
            
            -- Terapkan aksi tagging
            catalog:withWriteAccessDo("SnapSort Sync Tagging", function(context)
                for _, photo in ipairs(matchedPhotos) do
                    if props.actionType == "color" then
                        photo:setRawMetadata('colorNameForLabel', props.selectedColor)
                    elseif props.actionType == "flag" then
                        photo:setRawMetadata('pickStatus', props.selectedFlag)
                    elseif props.actionType == "rating" then
                        photo:setRawMetadata('rating', props.selectedRating)
                    end
                end
            end)
            
            -- Tampilkan summary
            local summaryMsg = ""
            if props.actionType == "color" then
                summaryMsg = string.format("Berhasil menandai %d foto dengan warna %s.", #matchedPhotos, props.selectedColor)
            elseif props.actionType == "flag" then
                local flagName = "Flagged"
                if props.selectedFlag == 0 then flagName = "Unflagged"
                elseif props.selectedFlag == -1 then flagName = "Rejected" end
                summaryMsg = string.format("Berhasil menandai %d foto dengan flag %s.", #matchedPhotos, flagName)
            elseif props.actionType == "rating" then
                summaryMsg = string.format("Berhasil menandai %d foto dengan rating %d stars.", #matchedPhotos, props.selectedRating)
            end
            
            if #notFoundCodes > 0 then
                local notFoundStr = table.concat(notFoundCodes, ", ")
                -- Truncate string jika terlalu panjang
                if string.len(notFoundStr) > 200 then
                    notFoundStr = string.sub(notFoundStr, 1, 197) .. "..."
                end
                
                local infoMsg = string.format("Namun, %d kode berikut tidak ditemukan di target scope:\n%s", #notFoundCodes, notFoundStr)
                LrDialogs.message("SnapSort Sync Selesai", summaryMsg .. "\n\n" .. infoMsg, "info")
            else
                LrDialogs.message("SnapSort Sync Selesai", summaryMsg .. "\nSemua kode berhasil ditemukan!", "info")
            end
        end
    end)
end

-- Panggil fungsi via async task (diperlukan untuk menu item plugin)
LrTasks.startAsyncTask(function()
    showDialog()
end)
