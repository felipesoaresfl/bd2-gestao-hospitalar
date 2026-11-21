CREATE OR REPLACE VIEW vw_fila_classificacao_risco AS
SELECT
    a.id_atendimento,
    COALESCE(p.nome, cp.identificacao) AS paciente,
    cr.cor AS cor_classificacao,
    cr.descricao AS classificacao,
    cr.prioridade,
    cr.tempo_max_espera,
    t.data_hora AS horario_triagem,
    a.queixa_principal,
    f.nome AS enfermeiro_responsavel
FROM atendimento a
INNER JOIN triagem t
    ON a.id_atendimento = t.id_atendimento
INNER JOIN classificacao_risco cr
    ON t.id_classificacao = cr.id_classificacao
LEFT JOIN paciente p
    ON a.id_paciente = p.id_paciente
LEFT JOIN cadastro_provisorio cp
    ON a.id_cadastro_provisorio = cp.id_cadastro_provisorio
INNER JOIN funcionario f
    ON t.id_funcionario = f.id_funcionario
ORDER BY cr.prioridade ASC, t.data_hora ASC;
