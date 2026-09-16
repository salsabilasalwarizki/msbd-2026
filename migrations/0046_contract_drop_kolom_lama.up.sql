-- Migration 0046 UP: Drop kolom rental_rate dari tabel film
-- Fase: CONTRACT FINAL - menghapus bentuk lama
-- PERINGATAN: TIDAK BISA DI-ROLLBACK SEPENUHNYA!

ALTER TABLE lab4.film DROP COLUMN rental_rate;