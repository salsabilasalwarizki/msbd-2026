-- Diminta: membuktikan bahwa hashing bcrypt dengan garam menghasilkan keluaran berbeda untuk kata sandi yang sama.
-- Dipilih: menggunakan ekstensi pgcrypto fungsi crypt(..., gen_salt('bf', 8)).
-- Alternatif: md5() tanpa garam; tidak dipilih karena deterministik dan rentan terhadap serangan rainbow table.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

SELECT crypt('rahasia123', gen_salt('bf', 8)) AS hash_1,
       crypt('rahasia123', gen_salt('bf', 8)) AS hash_2;
