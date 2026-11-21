USE gestao_emergencia_hospitalar;

SELECT
    r.data_hora_resultado,
    COALESCE(p.nome, cp.identificacao) AS paciente,
    e.nome AS exame,
    r.resultado,
    f.nome AS liberado_por,
    c.nome AS cargo
FROM resultado_exame r
INNER JOIN solicitacao s ON s.id_solicitacao = r.id_solicitacao
INNER JOIN exame e ON e.id_exame = s.id_exame
INNER JOIN atendimento a ON a.id_atendimento = s.id_atendimento
INNER JOIN funcionario f ON f.id_funcionario = r.id_funcionario
INNER JOIN cargo c ON c.id_cargo = f.id_cargo
LEFT JOIN paciente p ON p.id_paciente = a.id_paciente
LEFT JOIN cadastro_provisorio cp ON cp.id_cadastro_provisorio = a.id_cadastro_provisorio
WHERE r.situacao = 'C'
ORDER BY r.data_hora_resultado DESC;
