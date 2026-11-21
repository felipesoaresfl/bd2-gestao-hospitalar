CREATE OR REPLACE VIEW vw_internacoes_leitos AS
SELECT
    i.id_internacao,
    a.id_atendimento,
    COALESCE(p.nome, cp.identificacao) AS paciente,
    f.nome AS funcionario_responsavel,
    i.motivo,
    i.tipo AS tipo_internacao,
    i.status AS status_internacao,
    i.data_hora_entrada,
    i.data_hora_saida,
    l.numero AS numero_leito,
    loc.nome AS local_internacao,
    o.data_hora_entrada AS entrada_leito,
    o.data_hora_saida AS saida_leito
FROM internacao i
INNER JOIN atendimento a
    ON i.id_atendimento = a.id_atendimento
LEFT JOIN paciente p
    ON a.id_paciente = p.id_paciente
LEFT JOIN cadastro_provisorio cp
    ON a.id_cadastro_provisorio = cp.id_cadastro_provisorio
INNER JOIN funcionario f
    ON i.id_funcionario = f.id_funcionario
LEFT JOIN ocupacao o
    ON i.id_internacao = o.id_internacao
LEFT JOIN leito l
    ON o.id_leito = l.id_leito
LEFT JOIN local loc
    ON l.id_local = loc.id_local;
