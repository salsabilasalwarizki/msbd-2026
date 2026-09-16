-- Migration 0045 DOWN: Hapus view fasad dan pasang kembali trigger

DROP VIEW IF EXISTS lab4.film_lama;

CREATE OR REPLACE FUNCTION lab4.sync_harga_ke_film()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE lab4.film
    SET rental_rate = NEW.harga
    WHERE film_id = NEW.film_id AND NEW.wilayah = 'ID';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sync_harga_ke_film
AFTER INSERT OR UPDATE ON lab4.harga_film
FOR EACH ROW
WHEN (NEW.wilayah = 'ID')
EXECUTE FUNCTION lab4.sync_harga_ke_film();