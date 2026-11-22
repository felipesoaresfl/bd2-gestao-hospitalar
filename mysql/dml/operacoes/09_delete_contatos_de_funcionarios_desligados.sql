USE gestao_emergencia_hospitalar;

SET SQL_SAFE_UPDATES = 0;

DELETE FROM contato
WHERE id_funcionario IN (SELECT id_funcionario FROM funcionario WHERE status = 'I');

SET SQL_SAFE_UPDATES = 1;

SELECT COUNT(*) AS contatos_de_desligados
FROM contato c
INNER JOIN funcionario f ON f.id_funcionario = c.id_funcionario
WHERE f.status = 'I';
