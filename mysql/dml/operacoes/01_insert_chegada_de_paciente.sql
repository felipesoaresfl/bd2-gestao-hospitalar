USE gestao_emergencia_hospitalar;

INSERT INTO paciente (nome, cpf, data_nasc, sexo, nome_mae, cartao_sus, tipo_sanguineo, id_convenio, numero_carteirinha)
VALUES (
    'Rodrigo Almeida Prado',
    '52998224725',
    '1988-03-14',
    'M',
    'Lúcia Prado Almeida',
    '700509876543210',
    'O+',
    (SELECT id_convenio FROM convenio WHERE nome = 'Unimed São José dos Campos'),
    '00347215098813402'
);

INSERT INTO historico_clinico (id_paciente, observacoes)
VALUES ((SELECT id_paciente FROM paciente WHERE cpf = '52998224725'), 'Sem comorbidades conhecidas. Nega tabagismo e etilismo.');

INSERT INTO alergia (id_historico, agente, tipo, gravidade, reacao)
VALUES ((SELECT h.id_historico FROM historico_clinico h INNER JOIN paciente p ON p.id_paciente = h.id_paciente WHERE p.cpf = '52998224725'), 'Dipirona', 'M', 'M', 'Urticária e edema de face');

INSERT INTO contraindicacao (id_historico, descricao, motivo)
VALUES ((SELECT h.id_historico FROM historico_clinico h INNER JOIN paciente p ON p.id_paciente = h.id_paciente WHERE p.cpf = '52998224725'), 'Dipirona (metamizol) e associações', 'Alergia à dipirona');

INSERT INTO contato (id_paciente, tipo, valor, nome_contato, principal)
VALUES
    ((SELECT id_paciente FROM paciente WHERE cpf = '52998224725'), 'C', '12991234567', NULL, 'S'),
    ((SELECT id_paciente FROM paciente WHERE cpf = '52998224725'), 'C', '12997654321', 'Juliana Prado (esposa)', 'N');

INSERT INTO endereco (id_paciente, cep, logradouro, numero, complemento, bairro, cidade, uf)
VALUES ((SELECT id_paciente FROM paciente WHERE cpf = '52998224725'), '12230000', 'Avenida Cidade Jardim', '1450', 'Apto 32 Bloco B', 'Jardim Satélite', 'São José dos Campos', 'SP');

INSERT INTO atendimento (id_paciente, id_funcionario, id_status, id_local, tipo_entrada, queixa_principal)
VALUES (
    (SELECT id_paciente FROM paciente WHERE cpf = '52998224725'),
    (SELECT id_funcionario FROM funcionario WHERE login = 'ana.cardoso'),
    (SELECT id_status FROM status_atendimento WHERE descricao = 'Aguardando triagem'),
    (SELECT id_local FROM local WHERE nome = 'Recepção principal'),
    'E',
    'Dor no peito em pontada que piora ao respirar fundo'
);

INSERT INTO triagem (id_atendimento, id_funcionario, id_classificacao, descricao_sintomas, observacao)
VALUES (
    (SELECT MAX(a.id_atendimento) FROM atendimento a INNER JOIN paciente p ON p.id_paciente = a.id_paciente WHERE p.cpf = '52998224725'),
    (SELECT id_funcionario FROM funcionario WHERE login = 'marcos.castro'),
    (SELECT id_classificacao FROM classificacao_risco WHERE cor = 'Amarelo'),
    'Dor torácica em pontada há 3 horas, pior à inspiração profunda, sem irradiação. Nega falta de ar.',
    'Alergia referida: dipirona.'
);

INSERT INTO sinais_vitais (id_atendimento, id_funcionario, pressao_sistolica, pressao_diastolica, frequencia_cardiaca,
                           frequencia_respiratoria, temperatura, saturacao_o2, glicemia, escala_dor)
VALUES (
    (SELECT MAX(a.id_atendimento) FROM atendimento a INNER JOIN paciente p ON p.id_paciente = a.id_paciente WHERE p.cpf = '52998224725'),
    (SELECT id_funcionario FROM funcionario WHERE login = 'marcos.castro'),
    132, 84, 92, 18, 36.8, 97, NULL, 6
);

SELECT a.id_atendimento, p.nome, sa.descricao AS status_atual, cr.cor, t.descricao_sintomas
FROM atendimento a
INNER JOIN paciente p ON p.id_paciente = a.id_paciente
INNER JOIN status_atendimento sa ON sa.id_status = a.id_status
INNER JOIN triagem t ON t.id_atendimento = a.id_atendimento
INNER JOIN classificacao_risco cr ON cr.id_classificacao = t.id_classificacao
WHERE p.cpf = '52998224725';
