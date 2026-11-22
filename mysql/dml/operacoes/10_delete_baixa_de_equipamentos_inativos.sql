USE gestao_emergencia_hospitalar;

SET SQL_SAFE_UPDATES = 0;

DELETE FROM equipamento
WHERE status = 'I';

SET SQL_SAFE_UPDATES = 1;

SELECT status, COUNT(*) AS equipamentos
FROM equipamento
GROUP BY status;
