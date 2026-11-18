-- Diminta: memeriksa apakah kunci atau teks terang terlihat dari sesi lain selagi enkripsi berjalan, lalu menyebut dua tempat lain yang perlu diperiksa.
-- Dipilih: sesi 1 menyetel kunci lalu menganggur (idle); sesi 2 membaca pg_stat_activity.
-- Alternatif: memeriksa hanya query yang sedang berjalan; tidak dipilih karena sesi idle tetap menampilkan query terakhirnya.
-- Dijalankan sebagai: postgres untuk sesi 2.

-- Sesi 1 (psql terpisah). Jalankan lalu BIARKAN TERBUKA dan idle:
--   SET app.kunci_kolom = 'kunci-lab11-jangan-dipakai-di-produksi';

-- Sesi 2 (psql terpisah, sebagai postgres). Jalankan saat sesi 1 idle:
SELECT pid, usename, state, left(query, 120) AS potongan_query
  FROM pg_stat_activity
 WHERE datname = 'msbd' AND pid <> pg_backend_pid();
-- Harapkan: sesi 1 berstatus idle dan potongan_query memuat teks kunci. Kunci TERLIHAT.
-- Enkripsi kolom (Q21) tidak menampilkan kunci di teks query, karena query-nya memakai current_setting('app.kunci_kolom'),
-- tetapi kunci tampak pada sesi mana pun yang menjalankan SET literal dan belum ditutup.

-- Dua tempat lain yang wajib diperiksa:
-- 1. Log server PostgreSQL (log_statement / log_min_duration_statement) yang dapat memuat teks SET lengkap.
-- 2. Riwayat perintah klien (psql_history) dan log aplikasi/APM yang merekam query mentah.
-- Pola perbaikan: kunci diambil dari secret manager oleh aplikasi dan disetel dengan set_config(..., true) per transaksi,
-- sehingga tidak ditulis sebagai literal di SQL yang dikirim dari aplikasi.
