-- Diminta: procedure lab5.process_rental yang membuat rental dan payment dalam satu transaksi.
-- Dipilih: LANGUAGE plpgsql dengan BEGIN...EXCEPTION untuk atomicity.
-- Alternatif: dua INSERT terpisah; tidak dipilih karena tidak atomik.

CREATE OR REPLACE PROCEDURE lab5.process_rental(
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
END;
$$;

-- Hitung sebelum
SELECT count(*) AS rental_sebelum FROM lab5.rental_tx;
SELECT count(*) AS payment_sebelum FROM lab5.payment_tx;

-- Panggil dengan nilai sah
CALL lab5.process_rental(2, 2, 1, 5.99);

-- Hitung sesudah (harus bertambah 1)
SELECT count(*) AS rental_sesudah FROM lab5.rental_tx;
SELECT count(*) AS payment_sesudah FROM lab5.payment_tx;