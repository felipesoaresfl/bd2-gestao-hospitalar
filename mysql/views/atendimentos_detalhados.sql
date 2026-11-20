CREATE OR REPLACE VIEW vw_atendimentos_detalhados AS
SELECT
    a.id_atendimento,
    COALESCE(p.nome, cp.identificacao) AS paciente,
    CASE
        WHEN a.id_paciente IS NOT NULL THEN 'Identificado'
        ELSE 'Provisorio'
    END AS tipo_cadastro,
    f.nome AS funcionario_responsavel,
    sa.descricao AS status_atendimento,
    l.nome AS local_atendimento,
    cr.cor AS classificacao_risco,
    cr.descricao AS descricao_risco,
    t.data_hora AS data_triagem,
    a.data_hora_entrada,
    a.tipo_entrada,
    a.queixa_principal
FROM atendimento a
LEFT JOIN paciente p
    ON a.id_paciente = p.id_paciente
LEFT JOIN cadastro_provisorio cp
    ON a.id_cadastro_provisorio = cp.id_cadastro_provisorio
INNER JOIN funcionario f
    ON a.id_funcionario = f.id_funcionario
INNER JOIN status_atendimento sa
    ON a.id_status = sa.id_status
LEFT JOIN local l
    ON a.id_local = l.id_local
LEFT JOIN triagem t
    ON a.id_atendimento = t.id_atendimento
LEFT JOIN classificacao_risco cr
    ON t.id_classificacao = cr.id_classificacao;
