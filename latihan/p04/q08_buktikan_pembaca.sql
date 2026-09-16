-- Sisipkan 200000 akses baru
INSERT INTO lab4.jejak_akses (film_id, waktu, kanal)
SELECT (random() * 999)::int + 1, now(), 'web'
FROM generate_series(1, 200000);

-- Refresh concurrent (tidak akan blokir pembaca)
REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;

-- Query ini TIDAK akan diblokir oleh refresh concurrent
SELECT count(*) FROM lab4.ringkasan_akses;

-- Refresh biasa (AKAN memblokir pembaca)
REFRESH MATERIALIZED VIEW lab4.ringkasan_akses;

-- Query ini AKAN diblokir sampai refresh selesai
SELECT count(*) FROM lab4.ringkasan_akses;