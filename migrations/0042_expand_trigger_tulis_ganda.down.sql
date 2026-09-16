-- Migration 0042 DOWN: Hapus trigger tulis ganda

DROP TRIGGER IF EXISTS sync_harga_ke_film ON lab4.harga_film;
DROP FUNCTION IF EXISTS lab4.sync_harga_ke_film();