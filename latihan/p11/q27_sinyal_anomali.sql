-- Diminta: tiga query deteksi anomali dari jejak audit (lonjakan per pelaku, akses di luar jam kerja, ringkasan aksi).
-- Dipilih: agregasi per jam dan konversi zona waktu AT TIME ZONE 'Asia/Jakarta'.
-- Alternatif: memeriksa baris log satu per satu; tidak dipilih karena tidak skalabel.
-- Dijalankan sebagai: postgres.

-- 1. Lonjakan aksi per pelaku per jam (ambang 50 hanya contoh; sesuaikan dengan volume lab)
SELECT pelaku, date_trunc('hour', waktu) AS jam, count(*) AS jumlah_aksi
  FROM lab11.jejak_audit
 GROUP BY 1, 2
HAVING count(*) > 50;

-- 2. Akses di luar jam kerja: sebelum 07:00 atau mulai 19:00 WIB
SELECT id, waktu AT TIME ZONE 'Asia/Jakarta' AS waktu_wib, pelaku, aksi, tabel, kunci
  FROM lab11.jejak_audit
 WHERE EXTRACT(HOUR FROM waktu AT TIME ZONE 'Asia/Jakarta') NOT BETWEEN 7 AND 18;

-- 3. Ringkasan aksi per pelaku dan tabel
SELECT pelaku, tabel, aksi, count(*) AS total
  FROM lab11.jejak_audit
 GROUP BY 1, 2, 3
 ORDER BY total DESC;

-- Catatan untuk laporan: jejak_audit hanya mencatat UPDATE dan DELETE. Keluhan K2 (penyewa A MEMBACA data penyewa B)
-- adalah SELECT, sehingga tidak tertangkap oleh ketiga sinyal ini. Itu temuan penting: pembacaan perlu dicatat
-- dengan pgaudit atau log aplikasi. Jawab di laporan: sinyal mana yang paling mungkin menangkap K2, dan mengapa tidak ada yang sempurna.
