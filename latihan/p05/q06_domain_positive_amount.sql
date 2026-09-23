-- Diminta: mencoba insert amount nol dan negatif ke payment_tx.
-- Dipilih: dua INSERT terpisah untuk menunjukkan domain menolak kedua kasus.
-- Alternatif: satu INSERT dengan CASE; tidak dipilih karena tidak menunjukkan kedua error.

-- Uji amount = 0 (harus GAGAL)
INSERT INTO lab5.payment_tx (rental_id, amount) VALUES (1, 0);

-- Uji amount negatif (harus GAGAL)
INSERT INTO lab5.payment_tx (rental_id, amount) VALUES (1, -5.00);