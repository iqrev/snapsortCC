# SnapSort Sync

Plugin Adobe Lightroom Classic untuk mempercepat seleksi foto dengan menandai foto secara otomatis (Color Label, Pick/Reject Flag, Star Rating) langsung dari daftar kode atau teks mentah klien.

---

## Masalah yang Diselesaikan

Fotografer sering menerima daftar pilihan foto dari klien melalui chat WhatsApp, email, atau catatan teks dengan format beragam. Misalnya:

> "Halo mas, tolong proses yang DSC_0012, 0015, sama 0022 - 0025 ya"

Mencari satu per satu kode tersebut di katalog berisi ribuan foto sangat memakan waktu. SnapSort Sync mengekstrak kode foto dari teks mentah tersebut, mencocokkannya ke file di katalog Lightroom, lalu menerapkan label warna, flag, atau rating secara instan.

---

## Fitur Utama

- **Pencocokan Cerdas (Smart Pattern Parser)**:
  - Deteksi rentang angka otomatis (contoh: `0022 - 0025` langsung diurai menjadi `0022, 0023, 0024, 0025`).
  - Mengenali kode berawalan huruf dan simbol (seperti `DSC_0012`, `IMG_1020`, `_MG_4450`).
  - Ekstraksi angka mandiri tanpa terganggu teks percakapan biasa di sekitarnya.
  - Otomatis membersihkan ekstensi file umum (`.jpg`, `.arw`, `.cr2`, `.nef`, `.dng`) agar tidak mengacaukan deteksi angka.
- **Tiga Pilihan Aksi Tagging**:
  - **Color Label**: Red, Yellow, Green, Blue, Purple.
  - **Flag**: Flagged (Pick), Unflagged, Rejected.
  - **Rating**: 1 sampai 5 Bintang, atau 0 Bintang (None).
- **Live Preview Real-time**: Menampilkan jumlah dan cuplikan kode yang berhasil dideteksi saat teks dimasukkan ke form.
- **Fleksibilitas Scope**: Menandai seluruh foto di folder/koleksi aktif, atau hanya pada kumpulan foto yang diseleksi.
- **Privasi Terjaga & 100% Offline**: Berjalan sepenuhnya di engine lokal Lightroom Classic. Tidak memerlukan koneksi internet, tidak mengirim data ke server mana pun, dan bebas dari API eksternal.

---

## Persyaratan Sistem

- Adobe Lightroom Classic (kompatibel dengan Lightroom SDK 5.0 atau versi yang lebih baru).
- macOS atau Windows.

---

## Cara Instalasi

1. Unduh atau clone repository ini:
   ```bash
   git clone https://github.com/iqrev/snapsortCC.git
   ```
2. Buka Adobe Lightroom Classic.
3. Buka menu **File > Plug-in Manager...** (atau tekan shortcut `Cmd + Option + Shift + ,` di macOS / `Ctrl + Alt + Shift + ,` di Windows).
4. Klik tombol **Add** di bagian kiri bawah dialog Plug-in Manager.
5. Arahkan ke folder `SnapSortSync.lrplugin` di dalam repository yang telah diunduh, lalu pilih folder tersebut.
6. Pastikan status plugin menunjukkan **Installed and running**.
7. Klik **Done**.

---

## Cara Penggunaan

1. Buka Grid View (tekan tombol `G`) atau masuk ke modul **Library** di Lightroom Classic.
2. Buka folder atau koleksi foto yang ingin diproses.
3. (Opsional) Jika ingin membatasi pencarian pada foto tertentu saja, pilih/seleksi foto tersebut di Filmstrip terlebih dahulu. Jika tidak ada seleksi khusus, plugin akan memeriksa semua foto pada folder atau koleksi aktif.
4. Buka menu **Library > Plug-in Extras > SnapSort Sync - Tandai Foto**.
5. Salin dan tempel teks dari klien ke area **Daftar Kode Foto dari Klien**.
6. Tentukan **Aksi / Tagging** (Color Label, Flag, atau Rating) beserta nilainya.
7. Periksa kotak preview untuk memastikan kode terbaca dengan benar.
8. Klik tombol **Tandai Foto**.
9. Plugin akan memproses seluruh foto dan menampilkan dialog hasil: jumlah foto yang berhasil ditandai dan daftar kode yang tidak ditemukan di katalog (jika ada).

---

## Contoh Format Input yang Didukung

Parser dapat membaca berbagai variasi format penulisan:

| Format Input | Hasil Deteksi |
| :--- | :--- |
| `DSC_0012, 0015, 0022` | `DSC_0012`, `0015`, `0022` |
| `0022 - 0025` | `0022`, `0023`, `0024`, `0025` |
| `bang foto yang ini ya: DSC0100 sama 0104-0106` | `0104`, `0105`, `0106`, `DSC0100` |
| File dengan ekstensi: `REV00003 2.JPG, REV00010.CR2` | `REV00003`, `REV00010` |

---

## Pengujian Mandiri (CLI Standalone)

Logika parsing regex dan ekstraksi teks dapat diuji langsung dari terminal tanpa perlu membuka Lightroom Classic (membutuhkan `lua` versi 5.1 atau lebih baru yang terpasang di sistem):

```bash
cd snapsortCC
lua -e "local Parser = dofile('SnapSortSync.lrplugin/Parser.lua'); local hasil = Parser.parse('tolong DSC_0012, 0015, dan 0022 - 0025'); print(table.concat(hasil, ', '))"
```

Output:
```text
0022, 0023, 0024, 0025, DSC_0012, 0015
```

---

## Struktur Folder

```text
snapsortCC/
├── .gitignore
├── LICENSE
├── README.md
└── SnapSortSync.lrplugin/
    ├── Info.lua           # Manifest plugin (metadata, versi, registrasi menu)
    ├── SnapSortSync.lua   # Antarmuka modal dialog dan eksekusi katalog Lightroom
    ├── Parser.lua         # Modul ekstraksi teks dan pola regex Lua
    ├── Matcher.lua        # Modul pencocokan nama file dengan database foto
    └── README.md          # Dokumentasi ringkas plugin
```

---

## Keamanan dan Privasi

- Plugin tidak melakukan transmisi jaringan dalam bentuk apa pun.
- Tidak menyimpan riwayat teks klien di penyimpanan eksternal.
- Hanya memodifikasi metadata seleksi (label warna, flag, atau rating) melalui API resmi Adobe Lightroom SDK.

---

## Kontribusi

Kontribusi berupa saran fitur, laporan bug, atau pull request sangat diterima. Silakan buka issue baru melalui tab GitHub Issues jika menemukan kendala.

---

## Lisensi

Proyek ini dirilis di bawah lisensi [MIT License](LICENSE).
