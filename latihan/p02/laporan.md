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

# Keluaran atau ringkasan status migration.
    PS D:\Documents\msbd-2026> docker compose run --rm flyway info
    [+]  1/1t 1/11
    ✔ Container msbd-pg Running                                                                                     0.0s
    Container msbd-pg Waiting 
    Container msbd-pg Healthy 
    Container msbd-2026-flyway-run-03c5d0fd9622 Creating 
    Container msbd-2026-flyway-run-03c5d0fd9622 Created 
    WARNING: Storing migrations in 'sql' is not recommended and default scanning of this location may be deprecated in a future release
    Flyway OSS Edition 11.20.3 by Redgate

    See release notes here: https://rd.gt/416ObMi
    Database: jdbc:postgresql://postgres:5432/proyek_dev (PostgreSQL 17.11)
    Schema version: 4

    +-----------+---------+------------------------------------+------+---------------------+---------+----------+
    | Category  | Version | Description                        | Type | Installed On        | State   | Undoable |
    +-----------+---------+------------------------------------+------+---------------------+---------+----------+
    | Versioned | 1       | skema awal                         | SQL  | 2026-09-02 04:39:55 | Success | No       |
    | Versioned | 2       | petugas langkah1 tambah nullable   | SQL  | 2026-09-02 04:49:35 | Success | No       |
    | Versioned | 3       | petugas langkah2 isi data lama     | SQL  | 2026-09-02 04:49:37 | Success | No       |
    | Versioned | 4       | petugas langkah3 pasang constraint | SQL  | 2026-09-02 04:49:38 | Success | No       |
    +-----------+---------+------------------------------------+------+---------------------+---------+----------+

    PS D:\Documents\msbd-2026> 

# Bukti database dapat dibangun ulang menggunakan migration.
    PS D:\Documents\msbd-2026> docker compose exec postgres psql -U msbd -d postgres -c "DROP DATABASE proyek_dev;"
    DROP DATABASE
    PS D:\Documents\msbd-2026> docker compose exec postgres psql -U msbd -d postgres -c "CREATE DATABASE proyek_dev;"
    CREATE DATABASE
    PS D:\Documents\msbd-2026> docker compose run --rm flyway migrate
    [+]  1/1t 1/11
    ✔ Container msbd-pg Running                                                                                     0.0s
    Container msbd-pg Waiting 
    Container msbd-pg Healthy 
    Container msbd-2026-flyway-run-33bd4ad76ceb Creating 
    Container msbd-2026-flyway-run-33bd4ad76ceb Created 
    WARNING: Storing migrations in 'sql' is not recommended and default scanning of this location may be deprecated in a future release
    Flyway OSS Edition 11.20.3 by Redgate

    See release notes here: https://rd.gt/416ObMi
    Database: jdbc:postgresql://postgres:5432/proyek_dev (PostgreSQL 17.11)
    Schema history table "public"."flyway_schema_history" does not exist yet
    Successfully validated 4 migrations (execution time 00:00.572s)
    Creating Schema History table "public"."flyway_schema_history" ...
    Current version of schema "public": << Empty Schema >>
    Migrating schema "public" to version "1 - skema awal"
    Migrating schema "public" to version "2 - petugas langkah1 tambah nullable"
    Migrating schema "public" to version "3 - petugas langkah2 isi data lama"
    Migrating schema "public" to version "4 - petugas langkah3 pasang constraint"
    Successfully applied 4 migrations to schema "public", now at version v4 (execution time 00:00.505s)
    PS D:\Documents\msbd-2026> docker compose run --rm flyway info
    [+]  1/1t 1/11
    ✔ Container msbd-pg Running                                                                                     0.0s
    Container msbd-pg Waiting 
    Container msbd-pg Healthy 
    Container msbd-2026-flyway-run-e0342a713daf Creating 
    Container msbd-2026-flyway-run-e0342a713daf Created 
    WARNING: Storing migrations in 'sql' is not recommended and default scanning of this location may be deprecated in a future release
    Flyway OSS Edition 11.20.3 by Redgate

    See release notes here: https://rd.gt/416ObMi
    Database: jdbc:postgresql://postgres:5432/proyek_dev (PostgreSQL 17.11)
    Schema version: 4

    +-----------+---------+------------------------------------+------+---------------------+---------+----------+
    | Category  | Version | Description                        | Type | Installed On        | State   | Undoable |
    +-----------+---------+------------------------------------+------+---------------------+---------+----------+
    | Versioned | 1       | skema awal                         | SQL  | 2026-09-02 08:16:50 | Success | No       |
    | Versioned | 2       | petugas langkah1 tambah nullable   | SQL  | 2026-09-02 08:16:51 | Success | No       |
    | Versioned | 3       | petugas langkah2 isi data lama     | SQL  | 2026-09-02 08:16:51 | Success | No       |
    | Versioned | 4       | petugas langkah3 pasang constraint | SQL  | 2026-09-02 08:16:52 | Success | No       |
    +-----------+---------+------------------------------------+------+---------------------+---------+----------+

    PS D:\Documents\msbd-2026> 

# Bukti pola tiga langkah penambahan kolom NOT NULL.
    PS D:\Documents\msbd-2026> docker compose run --rm flyway migrate
    [+]  1/1t 1/11
    ✔ Container msbd-pg Running                                                                                     0.0s
    Container msbd-pg Waiting 
    Container msbd-pg Healthy 
    Container msbd-2026-flyway-run-9a1e559d6b77 Creating 
    Container msbd-2026-flyway-run-9a1e559d6b77 Created 
    WARNING: Storing migrations in 'sql' is not recommended and default scanning of this location may be deprecated in a future release
    Flyway OSS Edition 11.20.3 by Redgate

    See release notes here: https://rd.gt/416ObMi
    Database: jdbc:postgresql://postgres:5432/proyek_dev (PostgreSQL 17.11)
    Successfully validated 4 migrations (execution time 00:02.040s)
    Current version of schema "public": 4
    Schema "public" is up to date. No migration necessary.
    PS D:\Documents\msbd-2026> docker compose exec postgres psql -U msbd -d proyek_dev -c "\d distribusi_bantuan"
                                    Table "public.distribusi_bantuan"
        Column       |          Type          | Collation | Nullable |           Default            
    --------------------+------------------------+-----------+----------+------------------------------
    id_distribusi      | bigint                 |           | not null | generated always as identity
    id_lansia          | bigint                 |           | not null | 
    id_bantuan         | bigint                 |           | not null | 
    id_pendamping      | bigint                 |           | not null | 
    jumlah             | integer                |           | not null | 
    tgl_distribusi     | date                   |           | not null | CURRENT_DATE
    petugas_verifikasi | character varying(120) |           | not null | 
    Indexes:
        "distribusi_bantuan_pkey" PRIMARY KEY, btree (id_distribusi)
    Check constraints:
        "distribusi_bantuan_jumlah_check" CHECK (jumlah > 0)
    Foreign-key constraints:
        "distribusi_bantuan_id_bantuan_fkey" FOREIGN KEY (id_bantuan) REFERENCES jenis_bantuan(id_bantuan)
        "distribusi_bantuan_id_lansia_fkey" FOREIGN KEY (id_lansia) REFERENCES lansia(id_lansia)
        "distribusi_bantuan_id_pendamping_fkey" FOREIGN KEY (id_pendamping) REFERENCES pendamping(id_pendamping)

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

# Pengamatan dari pg_stat_activity.
    PS D:\Documents\msbd-2026> docker compose exec postgres psql -U msbd -d proyek_dev -c "SELECT pid, wait_event_type, state, left(query, 60) AS query FROM pg_stat_activity WHERE datname = 'proyek_dev';"
    pid  | wait_event_type | state  |                            query                             
    ------+-----------------+--------+--------------------------------------------------------------
    2934 |                 | active | SELECT pid, wait_event_type, state, left(query, 60) AS query
    (1 row)

### 1.  Mengapa lingkungan pengujian memerlukan basis data sendiri, dan bukan sekadar schema terpisah di dalam basis data yang sama? Jawab dalam sekitar dua kalimat
    Lingkungan pengujian memerlukan basis data yang terisolasi secara penuh untuk mencegah risiko kontaminasi data atau konflik skema yang dapat mengganggu lingkungan utamanya. Pemisahan ini memastikan bahwa operasi destruktif (seperti penghapusan tabel) selama pengujian tidak akan berdampak pada integritas dan ketersediaan data di lingkungan databasenya.

### 2.  Pilih satu kebutuhan yang memiliki aturan paling rumit. Menurut kelompok kalian, apakah aturan tersebut lebih tepat ditegakkan menggunakan constraint, trigger, atau kode aplikasi? Berikan satu alasan.
    Kelompok kami memilih kebutuhan KD-04 (Jadwal Pendampingan) dengan aturan pencegahan bentrok jadwal. Aturan ini lebih tepat ditegakkan menggunakan kode aplikasi karena logika validasi waktu yang dinamis dan kompleks lebih mudah diimplementasikan, diuji, dan dimodifikasi pada lapisan bisnis aplikasi dibandingkan menggunakan constraint atau trigger basis data yang cenderung kaku dan sulit di-debug.

### 3.  Mengapa Peminjaman dan Unit Alat pada contoh tidak dihubungkan langsung, tetapi melalui Baris Pinjam? Apa yang hilang jika hubungan dibuat langsung?
    Entitas Peminjaman dan Unit Alat tidak dihubungkan secara langsung karena terdapat relasi banyak-ke-banyak (many-to-many) di antara keduanya. Jika dihubungkan langsung tanpa entitas perantara, sistem akan kehilangan kemampuan untuk merekam atribut spesifik dari setiap transaksi per item, seperti jumlah unit yang dipinjam dalam satu transaksi atau waktu pengembalian spesifik per unit alat.

### 4.  Apa perbedaan antara entitas Alat dan Unit Alat? Sebutkan satu pertanyaan bisnis yang hanya dapat dijawab jika keduanya dipisahkan.
    Entitas Alat merepresentasikan data master atau katalog jenis barang (misalnya "Laptop Model X"), sedangkan entitas Unit Alat merepresentasikan barang fisik individu yang memiliki identitas unik seperti nomor seri. Pertanyaan bisnis yang hanya dapat dijawab dengan pemisahan ini adalah: "Berapa banyak unit fisik dari jenis alat tertentu yang saat ini sedang dipinjam dan berapa yang masih tersedia di gudang?"

### 5.  Seorang anggota kelompok mengubah isi V1__skema_awal.sql setelah migration tersebut sudah diterapkan, kemudian melakukan push ke repositori. Apa yang terjadi ketika anggota lain menjalankan migration? Jelaskan penyebab error dan cara memperbaikinya tanpa menghapus riwayat migration.
    Anggota lain akan mengalami error checksum mismatch saat menjalankan migration. Hal ini terjadi karena Flyway menyimpan hash (checksum) dari file migration yang telah dieksekusi; jika isi file diubah, hash tersebut tidak akan cocok dengan yang tercatat di basis data sehingga Flyway menolak eksekusi demi keamanan. Cara memperbaikinya tanpa menghapus riwayat adalah dengan mengembalikan file V1 ke versi aslinya, lalu membuat file migration baru (misalnya V2) untuk menerapkan perubahan skema yang diinginkan.

### 6.  Catat apa yang terlihat pada pg_stat_activity. Perintah mana yang menunggu? Apa akibatnya jika kondisi tersebut terjadi pada basis data produksi saat banyak pengguna sedang mengakses sistem?
    Pada pg_stat_activity, terlihat bahwa perintah ALTER TABLE berstatus waiting dengan wait_event_type berupa Lock, yang menandakan perintah tersebut sedang menunggu selesainya transaksi lain yang belum di-commit. Jika kondisi ini terjadi pada basis data produksi dengan banyak pengguna, sistem akan mengalami blocking atau hang, di mana pengguna lain tidak dapat mengakses atau memodifikasi tabel tersebut hingga transaksi yang menahan lock tersebut diselesaikan.

### 7.  Mengapa seed data tidak diletakkan langsung di dalam migrations/? Sebutkan satu perbedaan sifat antara migration dan seed data.
    Seed data tidak diletakkan di dalam folder migrations karena keduanya memiliki tujuan dan sifat eksekusi yang berbeda. Migration bersifat immutable (tidak boleh diubah setelah dijalankan) dan hanya dieksekusi sekali untuk mengelola evolusi struktur skema (DDL), sedangkan seed data bersifat idempotent (dapat dijalankan berulang kali dengan hasil yang sama) untuk mengisi atau mereset data uji (DML) tanpa memengaruhi riwayat versi skema.

## Daftar kontribusi atau commit masing-masing anggota kelompok.

Salsabila Salwa Rizki (251402123) | Project Manager:
- latihan/p02/kebutuhan.md
- latihan/p02/bukti/erd.png
- latihan/p02/laporan.md (Domain, Alasan memilih domain, Ringkasan lingkup sistem, Ringkasan kebutuhan data, Penjelasan ERD)
- latihan/p02/laporan.md (Jawaban Pertanyaan 1 & 2)

Nadia Stevany Br Situmorang (251402073):
- docker-compose.yml
- latihan/p02/migrations/V1__skema_awal.sql
- latihan/p02/bukti/flyway-info.txt
- latihan/p02/bukti/rebuild-database.txt
- latihan/p02/laporan.md (Keluaran status migration, Bukti database dapat dibangun ulang)
- latihan/p02/laporan.md (Jawaban Pertanyaan 3 & 4)

Sina Mahdi Sitanggang (251402008):
- latihan/p02/migrations/V2__tambah_kolom_nullable.sql
- latihan/p02/migrations/V3__isi_data_lama.sql
- latihan/p02/migrations/V4__pasang_constraint_not_null.sql
- latihan/p02/bukti/pg-stat-activity.txt
- latihan/p02/laporan.md (Bukti pola tiga langkah, Pengamatan pg_stat_activity)
- latihan/p02/laporan.md (Jawaban Pertanyaan 5 & 6)

Jesqueen Maria Purba (251402099):
- latihan/p02/seeds/01_master_data.sql
- latihan/p02/bukti/seed-data.txt
- latihan/p02/README.md
- latihan/p02/laporan.md (Hasil seed data, Jawaban Pertanyaan 7)
