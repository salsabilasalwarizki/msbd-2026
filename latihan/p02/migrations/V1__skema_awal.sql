CREATE TABLE lansia (
    id_lansia bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nik varchar(16) NOT NULL UNIQUE,
    nama varchar(120) NOT NULL,
    tgl_lahir date NOT NULL,
    CONSTRAINT ck_usia CHECK (EXTRACT(YEAR FROM AGE(CURRENT_DATE, tgl_lahir)) >= 60)
);

CREATE TABLE pendamping (
    id_pendamping bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nama varchar(120) NOT NULL,
    status_aktif varchar(16) NOT NULL DEFAULT 'aktif' 
        CHECK (status_aktif IN ('aktif', 'non-aktif'))
);

CREATE TABLE jenis_bantuan (
    id_bantuan bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nama_bantuan varchar(100) NOT NULL UNIQUE,
    kategori varchar(50) NOT NULL
);

CREATE TABLE distribusi_bantuan (
    id_distribusi bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_lansia bigint NOT NULL REFERENCES lansia(id_lansia),
    id_bantuan bigint NOT NULL REFERENCES jenis_bantuan(id_bantuan),
    id_pendamping bigint NOT NULL REFERENCES pendamping(id_pendamping),
    jumlah int NOT NULL CHECK (jumlah > 0),
    tgl_distribusi date NOT NULL DEFAULT CURRENT_DATE
);