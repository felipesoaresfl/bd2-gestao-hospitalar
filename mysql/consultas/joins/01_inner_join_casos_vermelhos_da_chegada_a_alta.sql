USE gestao_emergencia_hospitalar;

SELECT
    a.id_atendimento,
    p.nome AS paciente,
    TIMESTAMPDIFF(YEAR, p.data_nasc, a.data_hora_entrada) AS idade,
    a.data_hora_entrada,
    a.queixa_principal,
    enf.nome AS enfermeiro_triagem,
    med.nome AS medico_alta,
    al.tipo AS tipo_alta,
    al.cid_final
FROM atendimento a
INNER JOIN paciente p ON p.id_paciente = a.id_paciente
INNER JOIN triagem t ON t.id_atendimento = a.id_atendimento
INNER JOIN classificacao_risco cr ON cr.id_classificacao = t.id_classificacao
INNER JOIN funcionario enf ON enf.id_funcionario = t.id_funcionario
INNER JOIN alta al ON al.id_atendimento = a.id_atendimento
INNER JOIN funcionario med ON med.id_funcionario = al.id_funcionario
WHERE cr.cor = 'Vermelho'
ORDER BY a.data_hora_entrada DESC;
