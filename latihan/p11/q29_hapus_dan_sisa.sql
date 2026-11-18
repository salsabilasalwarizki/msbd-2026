-- Diminta: menjalankan satu permintaan hapus subjek data, lalu menghitung di berapa tempat data subjek itu masih ditemukan.
-- Dipilih: catat permintaan, hapus transaksi lalu pelanggan (urutan menghormati relasi), hitung sisa di tabel utama, transaksi, dan jejak audit.
-- Alternatif: hanya DELETE pada tabel pelanggan; tidak dipilih karena melanggar integritas referensial dan menyisakan jejak.
-- Dijalankan sebagai: postgres. Subjek: pelanggan id 12 dan 13.
-- Harapan: sisa_tabel_utama = 0, sisa_transaksi = 0, sisa_jejak_audit = 2 (satu per baris yang dihapus, dengan NIK lama).

INSERT INTO lab11.permintaan_hapus (pelanggan_id) VALUES (12), (13);

DELETE FROM lab11.transaksi  WHERE pelanggan_id IN (12, 13);
DELETE FROM lab11.pelanggan  WHERE id IN (12, 13);

SELECT count(*) AS sisa_tabel_utama FROM lab11.pelanggan WHERE id IN (12, 13);
SELECT count(*) AS sisa_transaksi   FROM lab11.transaksi  WHERE pelanggan_id IN (12, 13);
SELECT count(*) AS sisa_jejak_audit FROM lab11.jejak_audit
 WHERE kunci IN ('12', '13') AND nilai_lama ? 'nik';   -- audit justru menyimpan NIK lama

-- Tempat yang TIDAK bisa diukur dari lab ini (sebutkan di laporan, jangan diklaim nol):
-- replica (ikut primary, perlu dicek di server replica), cadangan dan arsip WAL (kedaluwarsa sesuai retensi),
-- ekspor/laptop analis (hanya bila tercatat), dan indeks pencarian di luar basis data.
