-- Diminta: menguji tiga UPDATE untuk membuktikan trigger hanya mencatat perubahan harga.
-- Dipilih: tiga skenario UPDATE untuk menguji kondisi WHEN.
-- Alternatif: UPDATE massal; tidak dipilih karena diminta uji per kasus.

-- Uji 1: Ubah harga (harusnya masuk audit)
UPDATE lab4.film SET rental_rate = 5.99 WHERE film_id = 1;

-- Uji 2: Tulis ulang harga sama (TIDAK boleh masuk audit)
UPDATE lab4.film SET rental_rate = 5.99 WHERE film_id = 1;

-- Uji 3: Ubah title saja (TIDAK boleh masuk audit)
UPDATE lab4.film SET title = 'Film Baru' WHERE film_id = 1;

-- Buktikan: harusnya cuma 1 baris audit
SELECT * FROM lab4.audit_harga ORDER BY audit_id DESC LIMIT 5;