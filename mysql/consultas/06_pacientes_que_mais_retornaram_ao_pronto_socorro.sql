USE gestao_emergencia_hospitalar;

SELECT
    p.id_paciente,
    p.nome,
    TIMESTAMPDIFF(YEAR, p.data_nasc, MAX(a.data_hora_entrada)) AS idade,
    COUNT(*) AS atendimentos,
    MIN(a.data_hora_entrada) AS primeira_visita,
    MAX(a.data_hora_entrada) AS ultima_visita
FROM atendimento a
INNER JOIN paciente p ON p.id_paciente = a.id_paciente
GROUP BY p.id_paciente, p.nome, p.data_nasc
HAVING COUNT(*) >= 3
ORDER BY atendimentos DESC, ultima_visita DESC;
