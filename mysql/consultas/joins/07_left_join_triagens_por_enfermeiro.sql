USE gestao_emergencia_hospitalar;

SELECT
    f.nome AS enfermeiro,
    f.status,
    COUNT(t.id_triagem) AS triagens,
    SUM(CASE WHEN cr.prioridade <= 2 THEN 1 ELSE 0 END) AS casos_vermelhos_e_laranjas,
    MAX(t.data_hora) AS ultima_triagem
FROM funcionario f
INNER JOIN cargo c ON c.id_cargo = f.id_cargo
LEFT JOIN triagem t ON t.id_funcionario = f.id_funcionario
LEFT JOIN classificacao_risco cr ON cr.id_classificacao = t.id_classificacao
WHERE c.nome IN ('Enfermeiro', 'Enfermeiro coordenador')
GROUP BY f.id_funcionario, f.nome, f.status
ORDER BY triagens DESC;
