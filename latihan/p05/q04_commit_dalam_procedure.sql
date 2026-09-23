-- Diminta: procedure dengan COMMIT di tengah, dipanggil dari Python dalam transaksi.
-- Dipilih: COMMIT eksplisit untuk membuktikan invalid transaction termination.
-- Alternatif: tanpa COMMIT; tidak dipilih karena tidak menguji kasus Q4.

CREATE OR REPLACE PROCEDURE lab5.process_rental_with_commit(
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

  COMMIT;  -- Ini akan error jika dipanggil dalam transaksi eksternal

  INSERT INTO lab5.payment_tx (rental_id, amount)
  VALUES (v_rental_id, p_amount);
END;
$$;

-- Uji langsung dari psql (harus berhasil karena tidak ada transaksi eksternal)
CALL lab5.process_rental_with_commit(4, 4, 1, 3.99);
SELECT count(*) FROM lab5.rental_tx;