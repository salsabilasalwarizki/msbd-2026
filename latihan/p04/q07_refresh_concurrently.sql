-- Diminta: mencoba REFRESH CONCURRENTLY, buat index unik, ulangi refresh.
-- Dipilih: UNIQUE INDEX pada (bulan, kanal) karena kombinasi itu unik di matview.
-- Alternatif: index pada satu kolom saja; tidak dipilih karena harus mencakup semua baris.

-- Coba refresh concurrent (harusnya error karena belum ada index unik)
REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;

-- Buat index unik
CREATE UNIQUE INDEX ux_ringkasan_akses_bulan_kanal
ON lab4.ringkasan_akses (bulan, kanal);

-- Refresh concurrent lagi dan catat waktu
\timing on
REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;
\timing off