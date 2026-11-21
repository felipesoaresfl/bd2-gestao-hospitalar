USE gestao_emergencia_hospitalar;

UPDATE funcionario
SET status = 'A'
WHERE login = 'fernanda.machado'
  AND status = 'F';

SELECT f.nome, c.nome AS cargo, f.status
FROM funcionario f
INNER JOIN cargo c ON c.id_cargo = f.id_cargo
WHERE f.login = 'fernanda.machado';
