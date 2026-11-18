-- Diminta: mengenkripsi kolom rekening dengan pgp_sym_encrypt dan membuktikan sifat probabilistiknya.
-- Dipilih: kunci disuntikkan lewat parameter sesi, dienkripsi 1000 baris pertama.
-- Alternatif: menyimpan nomor rekening sebagai teks biasa; tidak dipilih karena cadangan yang bocor langsung terbaca.
-- Dijalankan sebagai: postgres. Jalankan SEBELUM Q25 (trigger audit).
-- DEVIASI: skrip setup modul tidak punya kolom rekening. Kolom dibuat di sini dengan data sintetis (nomor 12 digit dari id).
--          Konfirmasi ke dosen sebelum dipakai untuk laporan.

SET app.kunci_kolom = 'kunci-lab11-jangan-dipakai-di-produksi';

ALTER TABLE lab11.pelanggan ADD COLUMN IF NOT EXISTS rekening text;
UPDATE lab11.pelanggan
   SET rekening = lpad((id::bigint * 7919 % 1000000000000)::text, 12, '0')
 WHERE rekening IS NULL;

ALTER TABLE lab11.pelanggan ADD COLUMN IF NOT EXISTS rekening_enc bytea;

UPDATE lab11.pelanggan
   SET rekening_enc = pgp_sym_encrypt(rekening, current_setting('app.kunci_kolom'))
 WHERE id <= 1000;

-- Dekripsi satu baris (harus sesi yang sama dengan SET di atas). Harapkan: rekening asli
SELECT id, pgp_sym_decrypt(rekening_enc, current_setting('app.kunci_kolom')) AS rekening_terbuka
  FROM lab11.pelanggan WHERE id = 1;

-- Sifat probabilistik. Harapkan: ciphertext_sama = f
SELECT pgp_sym_encrypt('x', 'k') = pgp_sym_encrypt('x', 'k') AS ciphertext_sama;
