-- Diminta: memverifikasi jumlah baris awal pada empat tabel skema lab11 di jaringan tertutup.
-- Dipilih: query SELECT count(*) dan GROUP BY tenant_id untuk memastikan data deterministik siap diuji.
-- Alternatif: mempercayai asumsi jumlah baris tanpa pengecekan; tidak dipilih karena seluruh uji bergantung pada angka dasar ini.

SELECT (SELECT count(*) FROM lab11.tenant)     AS tenant,
       (SELECT count(*) FROM lab11.pelanggan)  AS pelanggan,
       (SELECT count(*) FROM lab11.akun)       AS akun,
       (SELECT count(*) FROM lab11.transaksi)  AS transaksi;
-- harapkan: 3 | 30000 | 4 | 120000

SELECT tenant_id, count(*) FROM lab11.pelanggan GROUP BY 1 ORDER BY 1;
-- harapkan tiap penyewa 10000
