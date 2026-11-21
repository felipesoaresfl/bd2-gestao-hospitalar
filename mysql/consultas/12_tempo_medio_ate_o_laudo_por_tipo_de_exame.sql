USE gestao_emergencia_hospitalar;

SELECT
    te.nome AS tipo_exame,
    COUNT(*) AS laudos,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, s.data_hora, r.data_hora_resultado)) / 60.0, 1) AS media_horas_ate_laudo,
    ROUND(MIN(TIMESTAMPDIFF(MINUTE, s.data_hora, r.data_hora_resultado)) / 60.0, 1) AS mais_rapido_horas,
    ROUND(MAX(TIMESTAMPDIFF(MINUTE, s.data_hora, r.data_hora_resultado)) / 60.0, 1) AS mais_demorado_horas
FROM resultado_exame r
INNER JOIN solicitacao s ON s.id_solicitacao = r.id_solicitacao
INNER JOIN exame e ON e.id_exame = s.id_exame
INNER JOIN tipo_exame te ON te.id_tipo_exame = e.id_tipo_exame
WHERE s.prioridade = 'U'
GROUP BY te.id_tipo_exame, te.nome
HAVING AVG(TIMESTAMPDIFF(MINUTE, s.data_hora, r.data_hora_resultado)) > 60
ORDER BY media_horas_ate_laudo DESC;
