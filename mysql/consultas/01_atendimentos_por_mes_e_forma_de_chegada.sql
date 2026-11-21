USE gestao_emergencia_hospitalar;

SELECT
    DATE_FORMAT(data_hora_entrada, '%Y-%m') AS mes,
    COUNT(*) AS atendimentos,
    SUM(CASE WHEN tipo_entrada = 'E' THEN 1 ELSE 0 END) AS espontanea,
    SUM(CASE WHEN tipo_entrada = 'A' THEN 1 ELSE 0 END) AS ambulancia_samu,
    SUM(CASE WHEN tipo_entrada = 'B' THEN 1 ELSE 0 END) AS bombeiros_policia,
    ROUND(100.0 * SUM(CASE WHEN tipo_entrada IN ('A', 'B') THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_chegada_por_resgate
FROM atendimento
GROUP BY DATE_FORMAT(data_hora_entrada, '%Y-%m')
ORDER BY mes;
