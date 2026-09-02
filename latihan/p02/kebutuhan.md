## Lingkup

| Termasuk | Tidak termasuk |
|---|---|
| Data profil lansia dan kondisi kesehatan dasar | Penggajian atau honorarium pendamping |
| Katalog jenis bantuan (obat, makanan, alat kesehatan) | Manajemen logistik pengadaan obat dari pabrik |
| Penjadwalan kunjungan pendampingan ke rumah lansia | Sistem rekam medis rumah sakit yang kompleks |
| Pencatatan distribusi dan penerimaan bantuan | Pembayaran iuran atau asuransi kesehatan |

## Kebutuhan Data

### KD-01: Data Profil Lansia
- Deskripsi: Mencatat data identitas dan alamat lansia penerima bantuan
- Data: id_lansia, nik, nama, tgl_lahir, alamat, no_kontak_darurat
- Aturan: NIK harus unik; usia harus >= 60 tahun
- Volume: ±500 data
- Sumber: Data dari kelurahan/desa
- Prioritas: Wajib

### KD-02: Katalog Jenis Bantuan
- Deskripsi: Master data jenis bantuan yang tersedia
- Data: id_bantuan, nama_bantuan, kategori, satuan
- Aturan: Nama bantuan tidak boleh kosong
- Volume: ±50 jenis
- Sumber: Dinas Sosial/Kesehatan
- Prioritas: Wajib

### KD-03: Data Pendamping
- Deskripsi: Data petugas yang melakukan pendampingan
- Data: id_pendamping, nama, no_hp, status_aktif
- Aturan: Status hanya boleh 'aktif' atau 'non-aktif'
- Volume: ±50 orang
- Sumber: Rekrutmen internal
- Prioritas: Wajib

### KD-04: Jadwal Pendampingan
- Deskripsi: Penjadwalan kunjungan pendamping ke rumah lansia
- Data: id_jadwal, id_pendamping, id_lansia, tgl_kunjungan
- Aturan: Satu pendamping tidak boleh memiliki jadwal bentrok di waktu yang sama
- Volume: ±100 jadwal/minggu
- Sumber: Perencanaan bulanan
- Prioritas: Wajib

### KD-05: Transaksi Distribusi Bantuan
- Deskripsi: Pencatatan pemberian bantuan kepada lansia
- Data: id_distribusi, id_lansia, id_bantuan, jumlah, tgl_distribusi, id_pendamping
- Aturan: Jumlah tidak boleh negatif; tanggal tidak boleh di masa depan
- Volume: ±300 transaksi/bulan
- Sumber: Input real-time oleh pendamping
- Prioritas: Wajib

### KD-06: Riwayat Kondisi Khusus Lansia
- Deskripsi: Mencatat alergi atau kondisi medis kritis lansia
- Data: id_riwayat, id_lansia, jenis_kondisi, deskripsi
- Aturan: Kondisi 'kritis' memberikan prioritas antrian distribusi otomatis
- Volume: ±100 catatan
- Sumber: Assesment awal pendamping
- Prioritas: Tinggi

### KD-07: Stok Bantuan per Lokasi
- Deskripsi: Memantau ketersediaan bantuan di posko
- Data: id_posko, id_bantuan, jumlah_stok, tgl_update
- Aturan: Stok tidak boleh bernilai negatif (minimal 0)
- Volume: ±50 baris
- Sumber: Update harian admin gudang
- Prioritas: Tinggi

### KD-08: Feedback Penerima
- Deskripsi: Catatan keluhan atau masukan dari lansia
- Data: id_feedback, id_distribusi, rating, komentar
- Aturan: Rating bernilai 1-5; hanya bisa dibuat jika distribusi 'selesai'
- Volume: ±150 feedback/bulan
- Sumber: Input via aplikasi pendamping
- Prioritas: Rendah