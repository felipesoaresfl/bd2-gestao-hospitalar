USE gestao_emergencia_hospitalar;

SELECT
    COALESCE(c.nome, 'SUS / particular') AS convenio,
    COUNT(*) AS atendimentos,
    COUNT(DISTINCT a.id_paciente) AS pacientes,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM atendimento WHERE id_paciente IS NOT NULL), 1) AS pct_dos_atendimentos
FROM atendimento a
INNER JOIN paciente p ON p.id_paciente = a.id_paciente
LEFT JOIN convenio c ON c.id_convenio = p.id_convenio
GROUP BY c.id_convenio, c.nome
ORDER BY atendimentos DESC;
