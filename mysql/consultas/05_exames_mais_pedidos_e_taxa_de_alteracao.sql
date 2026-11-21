USE gestao_emergencia_hospitalar;

SELECT
    e.nome AS exame,
    te.nome AS tipo_exame,
    COUNT(*) AS laudos,
    SUM(CASE WHEN r.situacao = 'A' THEN 1 ELSE 0 END) AS alterados,
    SUM(CASE WHEN r.situacao = 'C' THEN 1 ELSE 0 END) AS criticos,
    ROUND(100.0 * SUM(CASE WHEN r.situacao IN ('A', 'C') THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_fora_do_normal
FROM resultado_exame r
INNER JOIN solicitacao s ON s.id_solicitacao = r.id_solicitacao
INNER JOIN exame e ON e.id_exame = s.id_exame
INNER JOIN tipo_exame te ON te.id_tipo_exame = e.id_tipo_exame
GROUP BY e.id_exame, e.nome, te.nome
HAVING COUNT(*) >= 100
ORDER BY laudos DESC;
