USE gestao_emergencia_hospitalar;

SET SQL_SAFE_UPDATES = 0;

UPDATE equipamento
SET status = 'D'
WHERE status = 'M'
  AND id_local IN (SELECT id_local FROM local WHERE tipo = 'U');

SET SQL_SAFE_UPDATES = 1;

SELECT l.nome AS local, e.nome AS equipamento, e.numero_patrimonio, e.status
FROM equipamento e
INNER JOIN local l ON l.id_local = e.id_local
WHERE l.tipo = 'U'
ORDER BY l.nome, e.nome;
