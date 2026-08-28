# SnapSort Sync (Lightroom Classic Plugin)

Plugin untuk mengotomatiskan penandaan foto (Color Label, Flag, Rating) di katalog Adobe Lightroom Classic berdasarkan daftar kode foto atau nama file dari klien.

## Cara Instalasi

1. Buka Adobe Lightroom Classic.
2. Buka **Plug-in Manager** melalui menu `File > Plug-in Manager...` (shortcut: `Cmd + Option + Shift + ,` di macOS atau `Ctrl + Alt + Shift + ,` di Windows).
3. Klik tombol **Add** di pojok kiri bawah.
4. Pilih folder `SnapSortSync.lrplugin` ini.
5. Pastikan status plugin tertulis **Installed and running**.
6. Klik **Done**.

## Cara Penggunaan

1. Buka Grid View (tekan tombol `G`) atau masuk ke mode Library di Lightroom Classic.
2. Buka folder atau koleksi foto yang ingin ditandai.
3. (Opsional) Pilih foto tertentu jika ingin membatasi pencarian hanya pada foto yang diseleksi.
4. Jalankan plugin melalui menu **Library > Plug-in Extras > SnapSort Sync - Tandai Foto**.
5. Dialog akan muncul:
   - **Text Area**: Paste teks mentah dari klien. Anda bisa mem-paste teks berantakan (contoh: `"bang yang ini ya DSC_0012, 0015, sama 0022 - 0025"`). Preview otomatis akan menampilkan jumlah kode yang terdeteksi.
   - **Aksi / Tagging**: Pilih aksi yang ingin diterapkan: Color Label, Flag (Pick/Reject), atau Rating (1 sampai 5 Bintang).
   - **Nilai**: Tentukan opsi nilai sesuai aksi yang dipilih.
6. Klik **Tandai Foto**.
7. Plugin akan memproses katalog dan menampilkan ringkasan foto yang berhasil ditandai beserta daftar kode yang tidak ditemukan jika ada.

## Pengujian Mandiri (CLI Tanpa Lightroom)

Logika parsing regex dapat diuji melalui terminal:

```bash
lua -e "local Parser = dofile('Parser.lua'); local result = Parser.parse('bang yang ini DSC_0012, 0015, dan 0022 - 0025 ya'); for _, v in ipairs(result) do print(v) end"
```

## Struktur File

- `Info.lua`: Manifest plugin (metadata ID, versi, menu UI).
- `SnapSortSync.lua`: File utama antarmuka dialog dan orchestrasi aksi ke katalog.
- `Parser.lua`: Modul ekstraksi teks dan regex Lua.
- `Matcher.lua`: Modul pencocokan kode dengan nama file di katalog Lightroom.
