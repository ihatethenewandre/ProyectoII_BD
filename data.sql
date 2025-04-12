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