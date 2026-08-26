Laporan Latihan 1 - Pertemuan 1 - Kelompok 9 - Manajemen Sistem Basis Data

Anggota Kelompok :
- Sina Mahdi Sitanggang (251402008)
- Nadia Stevany Br Situmorang (251402073)
- Jesqueen Maria Purba (251402099)
- Salsabila Salwa Rizki (251402123) : Project Manager


A. Keluaran docker --version:
    Docker version 29.7.2, buid a7dcaa6

B. Keluaran docker compose version
    Docker Compose version v5.4.0

C. Keluaran docker compose ps
    NAME         IMAGE            COMMAND                  SERVICE    CREATED       STATUS                 PORTS
    msbd-mongo   mongo:8          "docker-entrypoint.s…"   mongo      3 hours ago   Up 3 hours             0.0.0.0:27017->27017/tcp, [::]:27017->27017/tcp
    msbd-pg      postgres:17      "docker-entrypoint.s…"   postgres   3 hours ago   Up 3 hours (healthy)   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp
    msbd-redis   redis:7-alpine   "docker-entrypoint.s…"   redis      3 hours ago   Up 3 hours             0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp

D. Keluaran SELECT version();
    PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
    (1 row)

E. Jawaban tiga pertanyaan tentang Image, Container, dan Volume
    1. Apa yang dimaksud dengan Docker Image?

    Jawaban: Docker Image adalah sebuah templat atau cetakan yang berisi semua instruksi, kode, dan library yang dibutuhkan untuk menjalankan sebuah aplikasi. Image ini bersifat read-only (hanya bisa dibaca) dan tidak bisa diubah secara langsung. Ibaratnya, image ini adalah file installer atau resep dasar dari sebuah aplikasi sebelum dijalankan.

    2. Apa yang dimaksud dengan Container?

    Jawaban: Container adalah versi yang sedang berjalan (aktif) dari sebuah Docker Image. Jika image adalah cetakannya, maka container adalah hasil jadinya yang benar-benar bekerja di dalam sistem kita. Setiap container berjalan secara terisolasi (terpisah) dari sistem utama, namun tetap menggunakan sumber daya dari komputer host.

    3. Apa fungsi Volume?
    Jawaban: Volume berfungsi sebagai tempat penyimpanan data yang terpisah dari container. Tujuannya adalah agar data yang disimpan di dalam container (seperti data basis data) tidak ikut hilang ketika container tersebut dimatikan, dihapus, atau diperbarui. Dengan menggunakan volume, data kita akan tetap aman, tersimpan secara permanen, dan bisa digunakan kembali oleh container yang baru.

F. Jawaban empat pertanyaan pada Langkah 2
    1. Apa yang terjadi jika bagian volumes: pada layanan PostgreSQL dihapus, kemudian container dihentikan menggunakan docker compose down -v?

    Jawaban: Jika bagian volumes: dihapus dari konfigurasi, data PostgreSQL akan disimpan di dalam container itu sendiri (bukan di volume terpisah). Kalau container dihentikan dengan perintah docker compose down -v, flag -v akan menghapus semua volume yang terdaftar. Akibatnya, seluruh data basis data akan hilang permanen, termasuk semua tabel, user, password, dan data yang sudah dimasukkan. Container yang baru dibuat nanti akan benar-benar kosong seperti instalasi baru.

    2. Mengapa pemetaan port ditulis "5432:5432" dan bukan cukup satu angka? Apa yang harus diubah apabila komputer sudah memiliki PostgreSQL lain yang menggunakan port 5432?

    Jawaban: Penulisan "5432:5432" terdiri dari dua angka yang punya arti yang berbeda:
    Angka kiri (5432) adalah port di komputer/laptop kita (host)
    Angka kanan (5432) adalah port di dalam container Docker
    Jadi formatnya adalah "host_port:container_port". Kita butuh dua angka karena port di komputer kita bisa berbeda dengan port di dalam container.
    Jika komputer sudah memiliki PostgreSQL lain yang menggunakan port 5432, cukup ubah angka sebelah kiri saja. Misalnya menjadi "5433:5432". Artinya, PostgreSQL di container tetap berjalan di port 5432 (internal), tapi mengaksesnya melalui port 5433 di laptop.

    3. Apa fungsi blok healthcheck? Mengapa healthcheck penting ketika terdapat layanan lain yang bergantung pada basis data?

    Jawaban: Fungsi blok healthcheck adalah untuk memastikan bahwa PostgreSQL benar-benar siap menerima koneksi, bukan sekadar container-nya sudah berjalan. Perintah pg_isready -U msbd akan terus memeriksa apakah database sudah responsif.
    Healthcheck penting karena ada perbedaan antara "container berjalan" dengan "database siap". Container bisa saja sudah running, tapi PostgreSQL masih butuh waktu untuk loading dan initialization. Jika ada layanan lain (seperti aplikasi web atau API) yang mencoba terhubung ke database sebelum database benar-benar siap, maka koneksi akan gagal dan menyebabkan error. Dengan healthcheck, Docker akan menunggu sampai database benar-benar healthy sebelum mengizinkan layanan lain untuk menggunakannya.

    4. Menyimpan password langsung di dalam docker-compose.yml merupakan praktik yang kurang baik. Sebutkan satu cara yang lebih aman dan jelaskan mengapa hal tersebut penting ketika berkas masuk ke repositori Git.

    Jawaban: Cara yang lebih aman adalah dengan menggunakan file .env untuk menyimpan password dan kredensial sensitif, lalu memanggilnya di docker-compose.yml menggunakan variabel environment.
    Kemudian, file .env wajib dimasukkan ke dalam .gitignore agar tidak ikut ter-upload ke repositori Git.
    Hal ini penting karena repositori Git (terutama yang public atau yang dibagikan ke tim) bisa diakses oleh banyak orang. Jika password tersimpan langsung di docker-compose.yml yang ter-commit ke Git, maka siapa saja yang memiliki akses ke repositori tersebut bisa melihat password database. Ini sangat berisiko untuk keamanan data. Dengan menggunakan file .env yang di-ignore oleh Git, password tetap aman di komputer lokal dan tidak tersebar ke repositori.

G. Perbandingan penggunaan psql dan DBeaver
    1. Satu aktivitas yang menurut Anda lebih cepat dilakukan menggunakan psql.
    
    Jawaban: Melihat daftar database yang ada dengan perintah \l lebih cepat di psql karena cukup ketik satu perintah dan langsung muncul hasilnya, tanpa perlu navigasi menu.

    2. Satu aktivitas yang menurut Anda lebih cepat dilakukan menggunakan DBeaver.
    
    Jawaban: Melihat struktur tabel dan relasi antar tabel lebih cepat di DBeaver karena bisa langsung lihat ER Diagram secara visual tanpa perlu ketik query manual.
