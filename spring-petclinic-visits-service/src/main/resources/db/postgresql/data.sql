INSERT INTO visits VALUES (1, 7, '2010-03-04', 'rabies shot') ON CONFLICT DO NOTHING;
INSERT INTO visits VALUES (2, 8, '2011-03-04', 'rabies shot') ON CONFLICT DO NOTHING;
INSERT INTO visits VALUES (3, 8, '2009-06-04', 'neutered') ON CONFLICT DO NOTHING;
INSERT INTO visits VALUES (4, 7, '2008-09-04', 'spayed') ON CONFLICT DO NOTHING;

-- Seed rows use explicit ids, so move the identity sequence past them
SELECT setval(pg_get_serial_sequence('visits', 'id'), (SELECT MAX(id) FROM visits));
