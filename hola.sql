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


-- USUARIOS DE PRUEBA
INSERT INTO app_user (username, email) VALUES
('alice' , 'alice@demo.com'),
('bob'   , 'bob@demo.com'),
('carol' , 'carol@demo.com'),
('dave'  , 'dave@demo.com'),
('erin'  , 'erin@demo.com');

-- EVENTO ÚNICO
INSERT INTO event (event_id, title, venue, event_ts)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Concierto Rock',
  'Auditorio Nacional',
  '2025-06-30 20:00:00'
);

-- SECCIONES PARA EL EVENTO
INSERT INTO section (section_id, event_id, name, price) VALUES
('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'VIP',     750.00),
('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'PLATEA',  450.00),
('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'GENERAL', 250.00);

-- ASIENTOS (20 por sección, total 60)
DO $$
DECLARE
    r TEXT;
    n INT;
BEGIN
  FOREACH r IN ARRAY ARRAY['A','B','C','D']
  LOOP
    FOR n IN 1..5 LOOP
      INSERT INTO seat(section_id, row_label, seat_number)
      VALUES ('10000000-0000-0000-0000-000000000001', r, n);

      INSERT INTO seat(section_id, row_label, seat_number)
      VALUES ('10000000-0000-0000-0000-000000000002', r, n);

      INSERT INTO seat(section_id, row_label, seat_number)
      VALUES ('10000000-0000-0000-0000-000000000003', r, n);
    END LOOP;
  END LOOP;
END $$;

-- RESERVAS INICIALES (simulan un estado previo)
INSERT INTO reservation (seat_id, user_id, event_id, status)
SELECT s.seat_id, u.user_id, '00000000-0000-0000-0000-000000000001', 'CONFIRMED'
FROM seat s
JOIN app_user u ON u.username = 'alice'
WHERE s.seat_number = 1 AND s.row_label = 'A';