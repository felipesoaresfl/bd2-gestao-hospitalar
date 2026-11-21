USE gestao_emergencia_hospitalar;

SELECT
    i.id_internacao,
    COALESCE(p.nome, cp.identificacao) AS paciente,
    i.tipo AS tipo_internacao,
    i.data_hora_entrada,
    TIMESTAMPDIFF(DAY, i.data_hora_entrada, NOW()) AS dias_internado,
    lo.nome AS local,
    l.numero AS leito,
    f.nome AS medico_responsavel
FROM internacao i
INNER JOIN atendimento a ON a.id_atendimento = i.id_atendimento
INNER JOIN funcionario f ON f.id_funcionario = i.id_funcionario
LEFT JOIN paciente p ON p.id_paciente = a.id_paciente
LEFT JOIN cadastro_provisorio cp ON cp.id_cadastro_provisorio = a.id_cadastro_provisorio
LEFT JOIN ocupacao o ON o.id_internacao = i.id_internacao AND o.data_hora_saida IS NULL
LEFT JOIN leito l ON l.id_leito = o.id_leito
LEFT JOIN local lo ON lo.id_local = l.id_local
WHERE i.status = 'A'
ORDER BY i.data_hora_entrada;
