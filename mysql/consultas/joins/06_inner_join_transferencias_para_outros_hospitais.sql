USE gestao_emergencia_hospitalar;

SELECT
    tr.data_hora,
    COALESCE(p.nome, cp.identificacao) AS paciente,
    i.motivo AS motivo_internacao,
    tr.destino,
    tr.motivo AS motivo_transferencia,
    f.nome AS autorizado_por
FROM transferencia tr
INNER JOIN internacao i ON i.id_internacao = tr.id_internacao
INNER JOIN atendimento a ON a.id_atendimento = i.id_atendimento
INNER JOIN funcionario f ON f.id_funcionario = tr.id_funcionario
LEFT JOIN paciente p ON p.id_paciente = a.id_paciente
LEFT JOIN cadastro_provisorio cp ON cp.id_cadastro_provisorio = a.id_cadastro_provisorio
WHERE tr.tipo = 'E'
ORDER BY tr.data_hora DESC;
