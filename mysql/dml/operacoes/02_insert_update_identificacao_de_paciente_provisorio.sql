USE gestao_emergencia_hospitalar;

SET SQL_SAFE_UPDATES = 0;

INSERT INTO paciente (nome, cpf, data_nasc, sexo, nome_mae, cartao_sus)
VALUES ('Sebastião Ribeiro Campos', '11144477735', '1977-06-02', 'M', 'Aparecida Ribeiro Campos', '898001234567012');

INSERT INTO historico_clinico (id_paciente, observacoes)
VALUES ((SELECT id_paciente FROM paciente WHERE cpf = '11144477735'), 'Hipertenso em uso de losartana 50 mg 2x/dia, segundo a família.');

INSERT INTO doenca (id_historico, nome, cid, cronica, observacao)
VALUES ((SELECT h.id_historico FROM historico_clinico h INNER JOIN paciente p ON p.id_paciente = h.id_paciente WHERE p.cpf = '11144477735'), 'Hipertensão arterial sistêmica', 'I10', 'S', 'Em uso de losartana 50 mg 2x/dia');

INSERT INTO contato (id_paciente, tipo, valor, nome_contato, principal)
VALUES ((SELECT id_paciente FROM paciente WHERE cpf = '11144477735'), 'C', '12988776655', 'Maria Ribeiro Campos (irmã)', 'S');

UPDATE cadastro_provisorio
SET id_paciente = (SELECT id_paciente FROM paciente WHERE cpf = '11144477735'),
    data_identificacao = NOW()
WHERE identificacao = 'Desconhecido 116'
  AND id_paciente IS NULL;

UPDATE atendimento
SET id_paciente = (SELECT id_paciente FROM paciente WHERE cpf = '11144477735')
WHERE id_cadastro_provisorio = (SELECT id_cadastro_provisorio FROM cadastro_provisorio WHERE identificacao = 'Desconhecido 116');

SET SQL_SAFE_UPDATES = 1;

SELECT cp.identificacao, cp.data_identificacao, p.nome, a.id_atendimento, a.queixa_principal
FROM cadastro_provisorio cp
INNER JOIN paciente p ON p.id_paciente = cp.id_paciente
INNER JOIN atendimento a ON a.id_cadastro_provisorio = cp.id_cadastro_provisorio
WHERE cp.identificacao = 'Desconhecido 116';
