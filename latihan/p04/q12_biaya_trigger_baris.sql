-- Diminta: membandingkan UPDATE massal dengan trigger aktif vs nonaktif.
-- Dipilih: DISABLE/ENABLE TRIGGER untuk mengukur overhead trigger per baris.
-- Alternatif: DROP + CREATE trigger; tidak dipilih karena DISABLE lebih cepat.

\timing on

-- Dengan trigger aktif
UPDATE lab4.film SET rental_rate = rental_rate + 0.01;

-- Matikan trigger
ALTER TABLE lab4.film DISABLE TRIGGER film_audit_harga;

-- Dengan trigger nonaktif
UPDATE lab4.film SET rental_rate = rental_rate + 0.01;

-- Nyalakan lagi
ALTER TABLE lab4.film ENABLE TRIGGER film_audit_harga;

\timing off