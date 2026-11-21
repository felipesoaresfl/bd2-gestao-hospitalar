USE gestao_emergencia_hospitalar;

SELECT
    s.id_solicitacao,
    s.data_hora AS solicitado_em,
    e.nome AS exame,
    s.prioridade,
    s.status,
    a.id_atendimento,
    COALESCE(p.nome, cp.identificacao) AS paciente
FROM solicitacao s
INNER JOIN exame e ON e.id_exame = s.id_exame
INNER JOIN atendimento a ON a.id_atendimento = s.id_atendimento
LEFT JOIN paciente p ON p.id_paciente = a.id_paciente
LEFT JOIN cadastro_provisorio cp ON cp.id_cadastro_provisorio = a.id_cadastro_provisorio
LEFT JOIN resultado_exame r ON r.id_solicitacao = s.id_solicitacao
WHERE s.tipo = 'E'
  AND s.status <> 'C'
  AND r.id_resultado IS NULL
ORDER BY s.prioridade DESC, s.data_hora;
