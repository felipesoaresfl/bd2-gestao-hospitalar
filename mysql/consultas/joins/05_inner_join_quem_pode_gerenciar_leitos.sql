USE gestao_emergencia_hospitalar;

SELECT
    f.nome AS funcionario,
    c.nome AS cargo,
    'Permissão do cargo' AS origem
FROM funcionario f
INNER JOIN cargo c ON c.id_cargo = f.id_cargo
INNER JOIN cargo_permissao cpe ON cpe.id_cargo = c.id_cargo
INNER JOIN permissao pe ON pe.id_permissao = cpe.id_permissao
WHERE pe.nome = 'GERENCIAR_LEITOS'
  AND f.status = 'A'

UNION

SELECT
    f.nome AS funcionario,
    c.nome AS cargo,
    'Permissão extra' AS origem
FROM funcionario f
INNER JOIN cargo c ON c.id_cargo = f.id_cargo
INNER JOIN funcionario_permissao fp ON fp.id_funcionario = f.id_funcionario
INNER JOIN permissao pe ON pe.id_permissao = fp.id_permissao
WHERE pe.nome = 'GERENCIAR_LEITOS'
  AND f.status = 'A'

ORDER BY origem DESC, cargo, funcionario;
