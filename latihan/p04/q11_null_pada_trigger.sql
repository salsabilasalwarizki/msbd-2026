-- Diminta: mengganti IS DISTINCT FROM dengan <>, uji dengan NULL.
-- Dipilih: perbandingan <> untuk menunjukkan kelemahan dengan NULL.
-- Alternatif: tetap IS DISTINCT FROM; tidak dipilih karena diminta menguji <>.

-- Ganti trigger pakai <>
DROP TRIGGER IF EXISTS film_audit_harga ON lab4.film;

CREATE TRIGGER film_audit_harga
AFTER UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
WHEN (OLD.rental_rate <> NEW.rental_rate)
EXECUTE FUNCTION lab4.catat_audit_harga();

-- Uji: ubah dari nilai ke NULL
UPDATE lab4.film SET rental_rate = NULL WHERE film_id = 2;

-- Uji: ubah dari NULL ke nilai
UPDATE lab4.film SET rental_rate = 3.99 WHERE film_id = 2;

-- Cek audit (harusnya TIDAK ada karena NULL <> nilai = UNKNOWN)
SELECT * FROM lab4.audit_harga WHERE film_id = 2;