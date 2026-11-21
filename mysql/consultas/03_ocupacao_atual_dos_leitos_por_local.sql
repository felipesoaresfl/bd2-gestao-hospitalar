USE gestao_emergencia_hospitalar;

SELECT
    lo.nome AS local,
    COUNT(*) AS total_leitos,
    SUM(CASE WHEN l.status = 'O' THEN 1 ELSE 0 END) AS ocupados,
    SUM(CASE WHEN l.status = 'L' THEN 1 ELSE 0 END) AS livres,
    SUM(CASE WHEN l.status IN ('H', 'M') THEN 1 ELSE 0 END) AS indisponiveis,
    ROUND(100.0 * SUM(CASE WHEN l.status = 'O' THEN 1 ELSE 0 END) / COUNT(*), 1) AS taxa_ocupacao
FROM leito l
INNER JOIN local lo ON lo.id_local = l.id_local
GROUP BY lo.id_local, lo.nome
ORDER BY taxa_ocupacao DESC, lo.nome;
