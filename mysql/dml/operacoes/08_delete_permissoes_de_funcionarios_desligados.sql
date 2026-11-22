USE gestao_emergencia_hospitalar;

SET SQL_SAFE_UPDATES = 0;

DELETE FROM funcionario_permissao
WHERE id_funcionario IN (SELECT id_funcionario FROM funcionario WHERE status = 'I');

SET SQL_SAFE_UPDATES = 1;

SELECT COUNT(*) AS permissoes_extras_de_desligados
FROM funcionario_permissao fp
INNER JOIN funcionario f ON f.id_funcionario = fp.id_funcionario
WHERE f.status = 'I';
