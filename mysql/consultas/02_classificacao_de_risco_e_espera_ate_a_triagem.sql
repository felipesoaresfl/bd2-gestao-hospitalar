USE gestao_emergencia_hospitalar;

SELECT
    cr.cor,
    cr.descricao,
    COUNT(*) AS atendimentos,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM triagem), 1) AS pct_do_total,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, a.data_hora_entrada, t.data_hora)), 1) AS media_min_ate_triagem,
    MAX(TIMESTAMPDIFF(MINUTE, a.data_hora_entrada, t.data_hora)) AS maior_espera_min
FROM triagem t
INNER JOIN classificacao_risco cr ON cr.id_classificacao = t.id_classificacao
INNER JOIN atendimento a ON a.id_atendimento = t.id_atendimento
GROUP BY cr.id_classificacao, cr.cor, cr.descricao, cr.prioridade
ORDER BY cr.prioridade;
