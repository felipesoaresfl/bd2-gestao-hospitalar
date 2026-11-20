CREATE OR REPLACE VIEW vw_solicitacoes_detalhadas AS
SELECT
    s.id_solicitacao,
    s.id_atendimento,
    COALESCE(p.nome, cp.identificacao) AS paciente,
    f.nome AS funcionario_solicitante,
    CASE
        WHEN s.tipo = 'P' THEN 'Procedimento'
        WHEN s.tipo = 'E' THEN 'Exame'
        WHEN s.tipo = 'I' THEN 'Insumo'
    END AS tipo_solicitacao,
    COALESCE(pr.nome, ex.nome, i.nome) AS item_solicitado,
    s.quantidade,
    s.prioridade,
    s.status,
    s.data_hora,
    s.observacao
FROM solicitacao s
INNER JOIN atendimento a
    ON s.id_atendimento = a.id_atendimento
LEFT JOIN paciente p
    ON a.id_paciente = p.id_paciente
LEFT JOIN cadastro_provisorio cp
    ON a.id_cadastro_provisorio = cp.id_cadastro_provisorio
INNER JOIN funcionario f
    ON s.id_funcionario = f.id_funcionario
LEFT JOIN procedimento pr
    ON s.id_procedimento = pr.id_procedimento
LEFT JOIN exame ex
    ON s.id_exame = ex.id_exame
LEFT JOIN insumo i
    ON s.id_insumo = i.id_insumo;
