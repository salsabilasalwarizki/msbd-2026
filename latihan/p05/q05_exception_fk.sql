-- Diminta: procedure dengan EXCEPTION untuk foreign key violation.
-- Dipilih: EXCEPTION WHEN foreign_key_violation dengan pesan ramah.
-- Alternatif: tanpa EXCEPTION; tidak dipilih karena error PostgreSQL terlalu teknis.

CREATE OR REPLACE PROCEDURE lab5.process_rental_safe(
  p_customer_id integer,
  p_inventory_id integer,
  p_staff_id integer,
  p_amount numeric
)
LANGUAGE plpgsql AS $$
DECLARE
  v_rental_id bigint;
BEGIN
  INSERT INTO lab5.rental_tx (customer_id, inventory_id, staff_id)
  VALUES (p_customer_id, p_inventory_id, p_staff_id)
  RETURNING rental_id INTO v_rental_id;

  INSERT INTO lab5.payment_tx (rental_id, amount)
  VALUES (v_rental_id, p_amount);
EXCEPTION
  WHEN foreign_key_violation THEN
    RAISE NOTICE 'Data referensi tidak valid: customer, inventory, atau staff tidak ditemukan.';
  WHEN check_violation THEN
    RAISE NOTICE 'Nilai tidak valid: %', SQLERRM;
END;
$$;

-- Uji dengan inventory_id yang tidak ada (harus notice, bukan error)
CALL lab5.process_rental_safe(1, 999999, 1, 4.99);

-- Cek apakah rental_tx bertambah (harusnya TIDAK karena payment gagal)
SELECT count(*) FROM lab5.rental_tx;