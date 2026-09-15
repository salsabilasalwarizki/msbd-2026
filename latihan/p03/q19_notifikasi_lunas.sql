-- Diminta: notifikasi berstatus lunas dengan nomor transaksi, kota, dan jumlah sebagai angka,
-- plus satu indeks GIN.
-- Dipilih: operator ->> untuk teks dan cast ::numeric untuk jumlah.
-- Alternatif: operator #>>; tidak dipilih karena ->> lebih umum.

-- Buat indeks GIN
CREATE INDEX IF NOT EXISTS idx_notifikasi_payload ON notifikasi USING GIN (payload);

-- Tampilkan definisi (jalankan di psql interaktif)
-- \d notifikasi

-- Query notifikasi lunas
SELECT
    payload->>'trx' AS nomor_transaksi,
    payload->'pelanggan'->>'kota' AS kota_pelanggan,
    (payload->>'jumlah')::numeric AS jumlah
FROM notifikasi
WHERE payload @> '{"status":"lunas"}'
ORDER BY nomor_transaksi;