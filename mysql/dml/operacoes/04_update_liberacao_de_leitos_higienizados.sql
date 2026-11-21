USE gestao_emergencia_hospitalar;

SET SQL_SAFE_UPDATES = 0;

UPDATE leito
SET status = 'L'
WHERE status = 'H';

SET SQL_SAFE_UPDATES = 1;

SELECT status, COUNT(*) AS leitos
FROM leito
GROUP BY status;
