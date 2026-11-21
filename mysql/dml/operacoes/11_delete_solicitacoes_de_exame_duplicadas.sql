USE gestao_emergencia_hospitalar;

SET SQL_SAFE_UPDATES = 0;

DELETE FROM solicitacao
WHERE tipo = 'E'
  AND status = 'C'
  AND observacao LIKE 'Cancelado: exame já realizado%';

SET SQL_SAFE_UPDATES = 1;

SELECT status, COUNT(*) AS solicitacoes
FROM solicitacao
WHERE tipo = 'E'
GROUP BY status;
