USE gestao_emergencia_hospitalar;

SET SQL_SAFE_UPDATES = 0;

UPDATE atendimento
SET id_status = (SELECT id_status FROM status_atendimento WHERE descricao = 'Aguardando atendimento médico')
WHERE id_paciente = (SELECT id_paciente FROM paciente WHERE cpf = '52998224725')
  AND id_status = (SELECT id_status FROM status_atendimento WHERE descricao = 'Aguardando triagem');

SET SQL_SAFE_UPDATES = 1;

SELECT a.id_atendimento, p.nome, sa.descricao AS status_atual
FROM atendimento a
INNER JOIN paciente p ON p.id_paciente = a.id_paciente
INNER JOIN status_atendimento sa ON sa.id_status = a.id_status
WHERE p.cpf = '52998224725';
