USE gestao_emergencia_hospitalar;

SELECT
    a.id_atendimento,
    p.nome AS paciente,
    cr.cor AS classificacao,
    a.data_hora_entrada,
    a.queixa_principal
FROM atendimento a
INNER JOIN paciente p ON p.id_paciente = a.id_paciente
INNER JOIN triagem t ON t.id_atendimento = a.id_atendimento
INNER JOIN classificacao_risco cr ON cr.id_classificacao = t.id_classificacao
WHERE cr.prioridade <= 2
  AND a.id_paciente IN (
        SELECT h.id_paciente
        FROM historico_clinico h
        INNER JOIN alergia al ON al.id_historico = h.id_historico
        WHERE al.tipo = 'M'
          AND al.gravidade IN ('M', 'G')
  )
ORDER BY a.data_hora_entrada DESC;
