-- Diminta: menunjukkan bahaya second-order SQL injection. Nilai berbahaya disimpan aman lewat INSERT berparameter, lalu dirangkai ulang oleh fungsi laporan.
-- Dipilih: laporan_kota_rentan (merangkai string) dibandingkan dengan laporan_kota_aman (USING), keduanya membaca nilai yang sama dari tabel.
-- Alternatif: hanya memvalidasi input saat INSERT; tidak dipilih karena muatan lolos validasi sintaks dan muncul lagi di laporan belakangan.
-- Tabel status_uji dibuat untuk latihan ini dan dihapus di akhir.

-- 1) Tabel uji (dijalankan postgres)
CREATE TABLE IF NOT EXISTS lab11.status_uji (id serial PRIMARY KEY, nilai text NOT NULL);
GRANT SELECT ON lab11.status_uji TO app_read;

-- 2) Simpan muatan lewat INSERT berparameter. Nilai tersimpan utuh sebagai teks.
PREPARE simpan (text) AS INSERT INTO lab11.status_uji (nilai) VALUES ($1) RETURNING id;
EXECUTE simpan ('Medan'' OR ''1''=''1');     -- harapkan: id = 1
DEALLOCATE simpan;
SELECT id, nilai FROM lab11.status_uji;      -- harapkan: nilai = Medan' OR '1'='1

-- 3) Fungsi laporan RENTAN: membaca nilai lalu merangkainya ulang dengan string.
CREATE OR REPLACE FUNCTION lab11.laporan_kota_rentan(p_id int)
RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE v_kota text; v_total bigint;
BEGIN
  SELECT nilai INTO v_kota FROM lab11.status_uji WHERE id = p_id;
  EXECUTE 'SELECT count(*) FROM lab11.pelanggan WHERE kota = ''' || v_kota || '''' INTO v_total;
  RETURN v_total;
END;
$$;

-- 4) Fungsi laporan AMAN: nilai hanya lewat USING.
CREATE OR REPLACE FUNCTION lab11.laporan_kota_aman(p_id int)
RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE v_kota text; v_total bigint;
BEGIN
  SELECT nilai INTO v_kota FROM lab11.status_uji WHERE id = p_id;
  EXECUTE 'SELECT count(*) FROM lab11.pelanggan WHERE kota = $1' INTO v_total USING v_kota;
  RETURN v_total;
END;
$$;

-- 5) Panggil keduanya sebagai app_laporan penyewa 1
BEGIN; SET LOCAL ROLE app_laporan; SET LOCAL app.tenant = '1';
SELECT lab11.laporan_kota_rentan(1) AS hasil_rentan;   -- harapkan 10000 (kondisi OR TRUE, dibatasi RLS)
SELECT lab11.laporan_kota_aman(1)   AS hasil_aman;     -- harapkan 0 (nilai dibaca sebagai teks literal)
COMMIT;

-- 6) Bersihkan setelah bukti dicatat (dijalankan postgres):
-- DROP FUNCTION lab11.laporan_kota_rentan(int);
-- DROP FUNCTION lab11.laporan_kota_aman(int);
-- DROP TABLE lab11.status_uji;
