# Peta Keluhan Tiket #1134 ke UU Nomor 27 Tahun 2022 (UU PDP)

| Keluhan | Kewajiban / Hak UU PDP | Pasal Relevan | Kontrol Teknis Pencegah (Lab 11) |
|---|---|---|---|
| **K1**: Satu akun (`app_admin`) memegang seluruh kunci dan menjalankan `DROP TABLE` | Kewajiban pengendali melindungi data pribadi dari pemrosesan tidak sah dan menjaga keamanan sistem pemrosesan | **Pasal 35** & **Pasal 39** | Pemisahan peran berlapis: pemilik skema (`skema_owner`) tidak pernah login; aplikasi memakai peran terbatas (`app_laporan`/`app_portal`) dengan prinsip hak minimum. |
| **K2**: Penyewa A membaca data penyewa B selama 11 hari akibat lupa `WHERE tenant_id` | Kewajiban mencegah akses tidak sah antar pihak dan menjamin integritas pemrosesan data | **Pasal 35** & **Pasal 39** | Penerapan **Row-Level Security (RLS)** dengan `FORCE ROW LEVEL SECURITY` dan konteks transaksi `SET LOCAL app.tenant`. |
| **K3**: Kotak pencarian rentan SQL injection dan mengembalikan seluruh isi tabel | Kewajiban pengamanan teknis sistem informasi terhadap serangan manipulasi query | **Pasal 35** | Pemisahan saluran perintah dan data melalui **query berparameter (`%s` / `$1`)** serta **daftar putih** untuk pengenal kolom/urutan. |
| **K4**: Berkas `pg_dump` dan WAL berpindah ke laptop analis tanpa perlindungan | Kewajiban melindungi kerahasiaan data pribadi saat penyimpanan maupun pemindahan salinan | **Pasal 35** & **Pasal 36** | **Enkripsi kolom/cadangan** (`pgcrypto`) serta penggunaan **tampilan tersamar (`v_pelanggan_samar`)** tanpa akses langsung ke tabel asli. |
| **K5**: Permintaan hapus datang, tetapi data masih hidup di salinan dan jejak audit | Hak subjek data mengakhiri pemrosesan & menghapus data, serta kewajiban merekam pemrosesan | **Pasal 8**, **Pasal 31**, & **Pasal 43** | Tabel `permintaan_hapus` bertenggat 72 jam, penghapusan berjenjang, retensi terukur, dan anonimisasi/pseudonimisasi atribut sensitif pada `jejak_audit`. |

## Catatan Verifikasi Pasal
Nomor pasal di atas dicek terhadap teks UU Nomor 27 Tahun 2022 (pasal.id):
- Pasal 8: hak subjek untuk mengakhiri pemrosesan, menghapus, dan/atau memusnahkan data.
- Pasal 31: kewajiban merekam seluruh kegiatan pemrosesan.
- Pasal 35: kewajiban melindungi dan memastikan keamanan data (langkah teknis).
- Pasal 36: kewajiban menjaga kerahasiaan data.
- Pasal 38: kewajiban melindungi data dari pemrosesan yang tidak sah (bisa ditambahkan untuk K1 dan K3).
- Pasal 39: kewajiban mencegah data diakses secara tidak sah.
- Pasal 42: kewajiban mengakhiri pemrosesan (masa simpan habis, tujuan tercapai, atau permintaan subjek).
- Pasal 43: kewajiban menghapus data (antara lain atas permintaan subjek).
- Pasal 46: pemberitahuan tertulis kegagalan perlindungan data. Relevan bila K4 (berkas hilang di laptop) terbukti sebagai kebocoran.
