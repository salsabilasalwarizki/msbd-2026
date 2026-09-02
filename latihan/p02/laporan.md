# Laporan Latihan 2 - Pertemuan 2 - Kelompok 9 - Manajemen Sistem Basis Data

# Anggota Kelompok :
- Sina Mahdi Sitanggang (251402008)
- Nadia Stevany Br Situmorang (251402073)
- Jesqueen Maria Purba (251402099)
- Salsabila Salwa Rizki (251402123) : Project Manager

# Domain: Sistem Distribusi Bantuan Kesehatan dan Pendampingan Lansia
    Alasan kelompok kami memilih domain ini adalah karena sistem distribusi bantuan kesehatan dan pendampingan lansia merupakan masalah nyata yang semakin relevan di Indonesia. Dengan meningkatnya populasi lansia setiap tahunnya, kebutuhan akan sistem pencatatan yang terstruktur untuk mendistribusikan bantuan dan menjadwalkan pendampingan menjadi sangat penting. Domain ini juga menarik karena memiliki aturan bisnis yang cukup kompleks, seperti penjadwalan yang tidak boleh bentrok, batasan usia penerima, dan pemantauan stok bantuan di beberapa posko, sehingga cocok untuk dipraktikkan dalam perancangan basis data.

# Ringkasan lingkup sistem.
    Sistem Distribusi Bantuan Kesehatan dan Pendampingan Lansia kami rancang untuk mengelola pencatatan dan pendistribusian bantuan kesehatan kepada lansia secara terstruktur. Sistem ini mencakup pengelolaan data profil lansia penerima bantuan, katalog jenis bantuan (obat, makanan, dan alat kesehatan), penjadwalan kunjungan pendampingan ke rumah lansia, serta pencatatan distribusi dan penerimaan bantuan.

# Ringkasan kebutuhan data yang dibuat.
    Sistem kami ini merumuskan delapan kebutuhan data utama untuk mendukung operasional distribusi bantuan dan pendampingan lansia. Kebutuhan tersebut mencakup pengelolaan data master (Profil Lansia, Katalog Jenis Bantuan, Data Pendamping, dan Posko), transaksi operasional (Jadwal Pendampingan, Transaksi Distribusi Bantuan, dan Stok Bantuan per Lokasi), serta data pendukung (Riwayat Kondisi Khusus Lansia dan Feedback Penerima). Setiap kebutuhan data telah didefinisikan dengan atribut, aturan bisnis, volume estimasi, dan prioritas yang jelas untuk memastikan integritas dan kelengkapan informasi dalam basis data.

# Penjelasan singkat ERD.
    Entity Relationship Diagram (ERD) yang dirancang terdiri dari sembilan entitas dengan kardinalitas yang terdefinisi dengan jelas. Entitas utama meliputi LANSIA, PENDAMPING, JENIS_BANTUAN, dan POSKO. Relasi banyak-ke-banyak (many-to-many) antara entitas-entitas tersebut diuraikan menggunakan entitas asosiatif, yaitu JADWAL_PENDAMPINGAN (antara Lansia dan Pendamping), DISTRIBUSI_BANTUAN (antara Lansia, Pendamping, dan Jenis Bantuan), serta STOK_BANTUAN (antara Posko dan Jenis Bantuan). Selain itu, terdapat entitas anak seperti RIWAYAT_KONDISI dan FEEDBACK yang merepresentasikan hubungan satu-ke-banyak (one-to-many) untuk mencatat riwayat medis dan penilaian penerima bantuan secara historis.

# Hasil seed data setelah dijalankan dua kali.
    PS D:\Documents\msbd-2026> Get-Content latihan/p02/seeds/01_master_data.sql | docker compose exec -T postgres psql -U msbd -d proyek_dev
    INSERT 0 3
    PS D:\Documents\msbd-2026> Get-Content latihan/p02/seeds/01_master_data.sql | docker compose exec -T postgres psql -U msbd -d proyek_dev
    INSERT 0 3
    PS D:\Documents\msbd-2026> docker compose exec postgres psql -U msbd -d proyek_dev -c "SELECT count(*) FROM jenis_bantuan;"
    count 
    -------
        3
    (1 row)


### 1.  Mengapa lingkungan pengujian memerlukan basis data sendiri, dan bukan sekadar schema terpisah di dalam basis data yang sama? Jawab dalam sekitar dua kalimat
    Lingkungan pengujian memerlukan basis data yang terisolasi secara penuh untuk mencegah risiko kontaminasi data atau konflik skema yang dapat mengganggu lingkungan utamanya. Pemisahan ini memastikan bahwa operasi destruktif (seperti penghapusan tabel) selama pengujian tidak akan berdampak pada integritas dan ketersediaan data di lingkungan databasenya.

### 2.  Pilih satu kebutuhan yang memiliki aturan paling rumit. Menurut kelompok kalian, apakah aturan tersebut lebih tepat ditegakkan menggunakan constraint, trigger, atau kode aplikasi? Berikan satu alasan.
    Kelompok kami memilih kebutuhan KD-04 (Jadwal Pendampingan) dengan aturan pencegahan bentrok jadwal. Aturan ini lebih tepat ditegakkan menggunakan kode aplikasi karena logika validasi waktu yang dinamis dan kompleks lebih mudah diimplementasikan, diuji, dan dimodifikasi pada lapisan bisnis aplikasi dibandingkan menggunakan constraint atau trigger basis data yang cenderung kaku dan sulit di-debug.

### 3.  Mengapa Peminjaman dan Unit Alat pada contoh tidak dihubungkan langsung, tetapi melalui Baris Pinjam? Apa yang hilang jika hubungan dibuat langsung?
    Entitas Peminjaman dan Unit Alat tidak dihubungkan secara langsung karena terdapat relasi banyak-ke-banyak (many-to-many) di antara keduanya. Jika dihubungkan langsung tanpa entitas perantara, sistem akan kehilangan kemampuan untuk merekam atribut spesifik dari setiap transaksi per item, seperti jumlah unit yang dipinjam dalam satu transaksi atau waktu pengembalian spesifik per unit alat.

### 4.  Apa perbedaan antara entitas Alat dan Unit Alat? Sebutkan satu pertanyaan bisnis yang hanya dapat dijawab jika keduanya dipisahkan.
    Entitas Alat merepresentasikan data master atau katalog jenis barang (misalnya "Laptop Model X"), sedangkan entitas Unit Alat merepresentasikan barang fisik individu yang memiliki identitas unik seperti nomor seri. Pertanyaan bisnis yang hanya dapat dijawab dengan pemisahan ini adalah: "Berapa banyak unit fisik dari jenis alat tertentu yang saat ini sedang dipinjam dan berapa yang masih tersedia di gudang?"

    
### 7.  Mengapa seed data tidak diletakkan langsung di dalam migrations/? Sebutkan satu perbedaan sifat antara migration dan seed data.
    Seed data tidak diletakkan di dalam folder migrations karena keduanya memiliki tujuan dan sifat eksekusi yang berbeda. Migration bersifat immutable (tidak boleh diubah setelah dijalankan) dan hanya dieksekusi sekali untuk mengelola evolusi struktur skema (DDL), sedangkan seed data bersifat idempotent (dapat dijalankan berulang kali dengan hasil yang sama) untuk mengisi atau mereset data uji (DML) tanpa memengaruhi riwayat versi skema.