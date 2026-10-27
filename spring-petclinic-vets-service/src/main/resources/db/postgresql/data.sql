INSERT INTO vets VALUES (1, 'James', 'Carter') ON CONFLICT DO NOTHING;
INSERT INTO vets VALUES (2, 'Helen', 'Leary') ON CONFLICT DO NOTHING;
INSERT INTO vets VALUES (3, 'Linda', 'Douglas') ON CONFLICT DO NOTHING;
INSERT INTO vets VALUES (4, 'Rafael', 'Ortega') ON CONFLICT DO NOTHING;
INSERT INTO vets VALUES (5, 'Henry', 'Stevens') ON CONFLICT DO NOTHING;
INSERT INTO vets VALUES (6, 'Sharon', 'Jenkins') ON CONFLICT DO NOTHING;

INSERT INTO specialties VALUES (1, 'radiology') ON CONFLICT DO NOTHING;
INSERT INTO specialties VALUES (2, 'surgery') ON CONFLICT DO NOTHING;
INSERT INTO specialties VALUES (3, 'dentistry') ON CONFLICT DO NOTHING;

INSERT INTO vet_specialties VALUES (2, 1) ON CONFLICT DO NOTHING;
INSERT INTO vet_specialties VALUES (3, 2) ON CONFLICT DO NOTHING;
INSERT INTO vet_specialties VALUES (3, 3) ON CONFLICT DO NOTHING;
INSERT INTO vet_specialties VALUES (4, 2) ON CONFLICT DO NOTHING;
INSERT INTO vet_specialties VALUES (5, 1) ON CONFLICT DO NOTHING;

-- Seed rows use explicit ids, so move the identity sequences past them
SELECT setval(pg_get_serial_sequence('vets', 'id'), (SELECT MAX(id) FROM vets));
SELECT setval(pg_get_serial_sequence('specialties', 'id'), (SELECT MAX(id) FROM specialties));
