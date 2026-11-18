-- Diminta: menyiapkan tujuh peran dan kepemilikan skema yang dipakai Q1–Q30. Skrip setup modul tidak membuat peran ini.
-- Dipilih: peran NOLOGIN untuk hak (skema_owner, app_read, app_write), peran LOGIN untuk aplikasi (app_laporan, app_portal, app_analitik), dan kepemilikan tabel dipindah ke skema_owner.
-- Alternatif: membiarkan tabel dimiliki postgres; tidak dipilih karena Q1 dan Q9 kehilangan maknanya.
-- Dijalankan sebagai: postgres. Kata sandi di bawah hanya untuk lab tertutup, jangan dipakai di tempat lain.

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'skema_owner') THEN CREATE ROLE skema_owner NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_read')     THEN CREATE ROLE app_read NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_write')    THEN CREATE ROLE app_write NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_laporan')  THEN CREATE ROLE app_laporan LOGIN PASSWORD 'laporan123'; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_portal')   THEN CREATE ROLE app_portal LOGIN PASSWORD 'portal123'; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_analitik') THEN CREATE ROLE app_analitik LOGIN PASSWORD 'analitik123'; END IF;
END $$;

-- Kepemilikan: skema_owner memiliki semua objek lab11 (tidak pernah login)
ALTER SCHEMA lab11 OWNER TO skema_owner;
ALTER TABLE lab11.tenant    OWNER TO skema_owner;
ALTER TABLE lab11.pelanggan OWNER TO skema_owner;
ALTER TABLE lab11.akun      OWNER TO skema_owner;
ALTER TABLE lab11.transaksi OWNER TO skema_owner;
-- Sequence transaksi_id_seq ikut pindah otomatis karena terhubung ke kolom id tabel transaksi.

-- Hak dasar untuk peran fungsional
GRANT USAGE ON SCHEMA lab11 TO app_read, app_write, app_analitik;
GRANT SELECT ON ALL TABLES IN SCHEMA lab11 TO app_read;
GRANT INSERT, UPDATE, DELETE ON lab11.pelanggan, lab11.transaksi TO app_write;
GRANT USAGE, SELECT ON SEQUENCE lab11.transaksi_id_seq TO app_write;
GRANT app_read TO app_write;

-- Keanggotaan peran login (Q14: app_laporan adalah anggota app_read)
GRANT app_read  TO app_laporan;
GRANT app_write TO app_portal;

-- Hak bawaan untuk tabel yang dibuat skema_owner (dibutuhkan Q3)
ALTER DEFAULT PRIVILEGES FOR ROLE skema_owner IN SCHEMA lab11 GRANT SELECT ON TABLES TO app_read;
