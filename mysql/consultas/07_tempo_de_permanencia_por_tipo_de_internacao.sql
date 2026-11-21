USE gestao_emergencia_hospitalar;

SELECT
    CASE tipo
        WHEN 'C' THEN 'Clínica'
        WHEN 'R' THEN 'Cirúrgica'
        WHEN 'U' THEN 'UTI'
    END AS tipo_internacao,
    COUNT(*) AS internacoes_encerradas,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, data_hora_entrada, data_hora_saida)) / 24.0, 1) AS media_dias,
    ROUND(MIN(TIMESTAMPDIFF(HOUR, data_hora_entrada, data_hora_saida)) / 24.0, 1) AS menor_dias,
    ROUND(MAX(TIMESTAMPDIFF(HOUR, data_hora_entrada, data_hora_saida)) / 24.0, 1) AS maior_dias
FROM internacao
WHERE status = 'E'
GROUP BY tipo
ORDER BY media_dias DESC;
