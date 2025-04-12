-- Habilita la generación de UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- TABLA: Usuarios
CREATE TABLE app_user (
    user_id    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username   TEXT NOT NULL UNIQUE,
    email      TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- TABLA: Eventos
CREATE TABLE event (
    event_id   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title      TEXT NOT NULL,
    venue      TEXT NOT NULL,
    event_ts   TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- TABLA: Secciones o Zonas
CREATE TABLE section (
    section_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id   UUID NOT NULL REFERENCES event(event_id) ON DELETE CASCADE,
    name       TEXT NOT NULL,
    price      NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    UNIQUE (event_id, name)
);

-- TABLA: Asientos
CREATE TABLE seat (
    seat_id    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    section_id UUID NOT NULL REFERENCES section(section_id) ON DELETE CASCADE,
    row_label  TEXT NOT NULL,
    seat_number INT NOT NULL CHECK (seat_number > 0),
    UNIQUE (section_id, row_label, seat_number)
);

-- TABLA: Reservas
CREATE TABLE reservation (
    reservation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    seat_id        UUID NOT NULL REFERENCES seat(seat_id) ON DELETE CASCADE,
    user_id        UUID NOT NULL REFERENCES app_user(user_id),
    event_id       UUID NOT NULL REFERENCES event(event_id) ON DELETE CASCADE,
    reserved_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    status         TEXT NOT NULL CHECK (status IN ('CONFIRMED','CANCELLED')),
    UNIQUE (seat_id)
);

-- TABLA: Bitácora de Simulaciones
CREATE TABLE run_log (
    run_id        SERIAL PRIMARY KEY,
    started_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    isolation_lvl TEXT NOT NULL,
    threads       INT  NOT NULL,
    seat_target   UUID NOT NULL,
    successes     INT  NOT NULL,
    failures      INT  NOT NULL,
    avg_ms        NUMERIC(10,2) NOT NULL
);
