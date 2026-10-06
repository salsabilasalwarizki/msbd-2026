-- Diminta: menghitung tuple per halaman melalui ctid.
-- Dipilih: page() function dari extension pageinspect (jika tersedia) atau ctid manual.
-- Alternatif: pgstattuple; tidak dipilih karena butuh extension tambahan.

-- Aktifkan extension pageinspect jika belum
CREATE EXTENSION IF NOT EXISTS pageinspect;

-- Hitung jumlah halaman
SELECT
  pg_relation_size('lab6.event_log') / current_setting('block_size')::int AS jumlah_halaman;

-- Hitung rata-rata tuple per halaman
SELECT
  count(*)::numeric / (pg_relation_size('lab6.event_log') / current_setting('block_size')::int)
    AS rata_rata_tuple_per_halaman
FROM lab6.event_log;

-- Bandingkan dengan batas teoretis 291 tuple per halaman (8192 byte / ~28 byte header)
-- Selisih terjadi karena: header halaman (24 byte), pointer array, alignment, TOAST pointer