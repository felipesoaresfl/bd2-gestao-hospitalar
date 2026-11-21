USE gestao_emergencia_hospitalar;

SELECT
    al.cid_final,
    COUNT(*) AS altas,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM alta WHERE tipo = 'M'), 1) AS pct_das_altas_medicas,
    ROUND(AVG(TIMESTAMPDIFF(YEAR, p.data_nasc, a.data_hora_entrada)), 0) AS idade_media
FROM alta al
INNER JOIN atendimento a ON a.id_atendimento = al.id_atendimento
INNER JOIN paciente p ON p.id_paciente = a.id_paciente
WHERE al.tipo = 'M'
  AND al.cid_final IS NOT NULL
GROUP BY al.cid_final
ORDER BY altas DESC
LIMIT 10;
