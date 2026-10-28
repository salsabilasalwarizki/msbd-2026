-- Diminta: membuat skema lab9 dan tabel rekening untuk eksperimen transaksi.
-- Dipilih: CHECK constraint saldo >= 0 untuk menjaga konsistensi.
-- Alternatif: tanpa CHECK; tidak dipilih karena bisa menyebabkan saldo negatif.

CREATE SCHEMA IF NOT EXISTS lab9;

-- Cek konfigurasi default
SHOW transaction_isolation;
SHOW deadlock_timeout;
SHOW lock_timeout;
SHOW statement_timeout;
SHOW idle_in_transaction_session_timeout;

-- Buat tabel rekening
CREATE TABLE lab9.rekening (
    rekening_id INT PRIMARY KEY,
    pemilik TEXT NOT NULL,
    saldo NUMERIC(12,2) NOT NULL CHECK (saldo >= 0)
);

-- Insert data awal (gunakan ON CONFLICT untuk idempotent)
INSERT INTO lab9.rekening VALUES
(1, 'Ani', 1000000),
(2, 'Budi', 1000000)
ON CONFLICT (rekening_id) DO UPDATE
SET pemilik = EXCLUDED.pemilik,
    saldo = EXCLUDED.saldo;

-- Verifikasi kondisi awal
SELECT * FROM lab9.rekening ORDER BY rekening_id;
SELECT SUM(saldo) AS total_saldo FROM lab9.rekening;