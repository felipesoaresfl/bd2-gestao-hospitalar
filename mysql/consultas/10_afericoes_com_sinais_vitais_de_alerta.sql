USE gestao_emergencia_hospitalar;

SELECT
    sv.data_hora,
    COALESCE(p.nome, cp.identificacao) AS paciente,
    sv.pressao_sistolica,
    sv.pressao_diastolica,
    sv.frequencia_cardiaca,
    sv.saturacao_o2,
    sv.temperatura
FROM sinais_vitais sv
INNER JOIN atendimento a ON a.id_atendimento = sv.id_atendimento
LEFT JOIN paciente p ON p.id_paciente = a.id_paciente
LEFT JOIN cadastro_provisorio cp ON cp.id_cadastro_provisorio = a.id_cadastro_provisorio
WHERE sv.saturacao_o2 < 90
   OR sv.pressao_sistolica < 90
   OR sv.temperatura >= 39.0
ORDER BY sv.data_hora DESC
LIMIT 30;
