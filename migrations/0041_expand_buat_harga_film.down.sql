-- Migration 0041 DOWN: Rollback tabel harga_film

DROP TABLE IF EXISTS lab4.harga_film CASCADE;
DROP EXTENSION IF EXISTS btree_gist CASCADE;