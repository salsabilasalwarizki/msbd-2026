CREATE SCHEMA IF NOT EXISTS lab11;

CREATE TABLE IF NOT EXISTS lab11.tenant (
  id int PRIMARY KEY,
  nama text NOT NULL
);

CREATE TABLE IF NOT EXISTS lab11.pelanggan (
  id int PRIMARY KEY,
  tenant_id int NOT NULL REFERENCES lab11.tenant(id),
  nama text NOT NULL,
  nik text NOT NULL,
  surel text NOT NULL,
  lahir date NOT NULL,
  kota text NOT NULL,
  saldo numeric(12,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS lab11.akun (
  id int PRIMARY KEY,
  nama_pengguna text NOT NULL,
  peran_aplikasi text NOT NULL,
  status text NOT NULL
);

CREATE TABLE IF NOT EXISTS lab11.transaksi (
  id bigserial PRIMARY KEY,
  pelanggan_id int NOT NULL REFERENCES lab11.pelanggan(id),
  jumlah numeric(12,2) NOT NULL,
  dibuat_pada timestamptz NOT NULL DEFAULT now()
);

INSERT INTO lab11.tenant (id, nama) VALUES (1, 'Tenant A'), (2, 'Tenant B'), (3, 'Tenant C') ON CONFLICT DO NOTHING;

INSERT INTO lab11.akun (id, nama_pengguna, peran_aplikasi, status) VALUES 
(1, 'sinta', 'operator', 'AKTIF'),
(2, 'bagas', 'penyelia', 'AKTIF'),
(3, 'ratna', 'operator', 'AKTIF'),
(4, 'yusuf', 'auditor', 'AKTIF')
ON CONFLICT DO NOTHING;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM lab11.pelanggan) THEN
    INSERT INTO lab11.pelanggan (id, tenant_id, nama, nik, surel, lahir, kota, saldo)
    SELECT 
      g.id,
      ((g.id - 1) / 10000) + 1 AS tenant_id,
      'Pelanggan ' || g.id AS nama,
      lpad(g.id::text, 16, '0') AS nik,
      'user' || g.id || '@contoh.ac.id' AS surel,
      date '2000-01-01' + (g.id % 365) AS lahir,
      CASE (g.id % 3) WHEN 0 THEN 'Medan' WHEN 1 THEN 'Jakarta' ELSE 'Bandung' END AS kota,
      (g.id * 100)::numeric(12,2) AS saldo
    FROM generate_series(1, 30000) AS g(id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM lab11.transaksi) THEN
    INSERT INTO lab11.transaksi (pelanggan_id, jumlah)
    SELECT 
      ((g.id - 1) % 30000) + 1 AS pelanggan_id,
      (g.id * 10)::numeric(12,2) AS jumlah
    FROM generate_series(1, 120000) AS g(id);
  END IF;
END $$;