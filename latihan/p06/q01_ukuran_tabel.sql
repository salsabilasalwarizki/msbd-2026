-- Diminta: mencatat ukuran total tabel dan menghitung rata-rata byte per baris.
-- Dipilih: pg_total_relation_size untuk ukuran termasuk index dan TOAST.
-- Alternatif: pg_relation_size saja; tidak dipilih karena tidak mencakup semua komponen.

-- Ukuran total tabel (termasuk index, TOAST, dll)
SELECT
  pg_size_pretty(pg_total_relation_size('lab6.event_log')) AS ukuran_total,
  pg_total_relation_size('lab6.event_log') AS ukuran_total_byte;

-- Ukuran heap saja (data mentah)
SELECT
  pg_size_pretty(pg_relation_size('lab6.event_log')) AS ukuran_heap,
  pg_relation_size('lab6.event_log') AS ukuran_heap_byte;

-- Rata-rata byte per baris (berdasarkan heap)
SELECT
  pg_relation_size('lab6.event_log')::numeric / count(*) AS rata_rata_byte_per_baris
FROM lab6.event_log;

-- Perkiraan teoretis dari definisi kolom
-- event_id: 8 byte (bigint)
-- customer_id: 4 byte (integer)
-- terjadi_pada: 8 byte (timestamptz)
-- status: ~8 byte (text, rata-rata)
-- wilayah: ~6 byte
-- kota: ~10 byte
-- email: ~25 byte
-- idempotency_key: 16 byte (uuid)
-- jumlah: 8 byte (numeric)
-- tags: ~30 byte (array 2 elemen)
-- payload: ~50 byte (jsonb)
-- Header tuple: ~23 byte
-- Total perkiraan: ~196 byte per baris