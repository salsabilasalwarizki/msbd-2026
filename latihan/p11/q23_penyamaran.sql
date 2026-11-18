-- Diminta: menyediakan tampilan tersamar bagi analis tanpa memberi akses langsung ke tabel asli, lalu membuktikan SELECT langsung ditolak.
-- Dipilih: CREATE VIEW ... WITH (security_barrier = true) tanpa security_invoker, sehingga analis tidak butuh hak pada tabel asli.
-- Alternatif: memberi akses langsung ke tabel pelanggan; tidak dipilih karena mengekspos NIK, nama lengkap, dan surel asli.
-- Dijalankan sebagai: postgres.

REVOKE pg_read_all_data FROM app_analitik;

CREATE OR REPLACE VIEW lab11.v_pelanggan_samar WITH (security_barrier = true) AS
SELECT id, tenant_id,
       left(nama,1) || repeat('*', greatest(length(nama)-1, 1))  AS nama,
       'xxxxxxxxxxxx' || right(nik, 4)                            AS nik,
       regexp_replace(surel, '^[^@]+', '****')                   AS surel,
       extract(year from lahir)::int                             AS lahir_tahun,
       kota,
       round(saldo, -5)                                          AS saldo_bulat
FROM lab11.pelanggan;

REVOKE ALL   ON lab11.pelanggan         FROM app_analitik;
GRANT SELECT ON lab11.v_pelanggan_samar TO   app_analitik;
-- Jika app_analitik belum punya USAGE pada skema lab11, tambahkan: GRANT USAGE ON SCHEMA lab11 TO app_analitik;

-- Uji positif dan negatif (jalankan semua, catat keluaran nyata):
SET ROLE app_analitik;
SELECT * FROM lab11.pelanggan LIMIT 1;           -- harapkan: ERROR permission denied for table pelanggan
SELECT * FROM lab11.v_pelanggan_samar LIMIT 5;   -- harapkan: 5 baris tersamar
SELECT count(*) AS jumlah_di_view FROM lab11.v_pelanggan_samar;
RESET ROLE;

-- Catatan RLS (perlu diverifikasi, bukan asumsi):
-- View tanpa security_invoker berjalan dengan hak pemilik view. Pemilik di sini adalah postgres (superuser),
-- yang melewati RLS. Maka count di atas kemungkinan 30000 (semua penyewa), bukan 10000.
-- Jika itu terjadi, catat sebagai temuan: tampilan tersamar BUKAN isolasi penyewa. Perbaikan yang diusulkan:
-- tambahkan filter tenant pada view, atau buat pemilik view peran tanpa BYPASSRLS yang tunduk kebijakan penyewa.
