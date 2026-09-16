-- Diminta: backfill dalam potongan 1000 film.
-- Dipilih: loop dengan BETWEEN untuk hindari lock lama.
-- Alternatif: satu INSERT besar; tidak dipilih karena akan lock tabel terlalu lama.

-- Backfill potongan pertama
INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
SELECT f.film_id, 'ID', f.rental_rate, daterange('2026-01-01', NULL)
FROM lab4.film f
WHERE f.film_id BETWEEN 1 AND 1000
  AND NOT EXISTS (
      SELECT 1 FROM lab4.harga_film h
      WHERE h.film_id = f.film_id AND h.wilayah = 'ID'
  );

-- Ulangi untuk rentang berikutnya (1001-2000, dst)
INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
SELECT f.film_id, 'ID', f.rental_rate, daterange('2026-01-01', NULL)
FROM lab4.film f
WHERE f.film_id BETWEEN 1001 AND 2000
  AND NOT EXISTS (
      SELECT 1 FROM lab4.harga_film h
      WHERE h.film_id = f.film_id AND h.wilayah = 'ID'
  );

-- Verifikasi (harusnya 0)
SELECT count(*)
FROM lab4.film f
WHERE NOT EXISTS (
    SELECT 1 FROM lab4.harga_film h
    WHERE h.film_id = f.film_id AND h.wilayah = 'ID'
);