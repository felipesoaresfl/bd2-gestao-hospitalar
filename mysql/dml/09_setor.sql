use gestao_emergencia_hospitalar;
set names utf8mb4;

insert into setor (id_setor, nome, descricao) values
(1, 'Recepção', 'Acolhimento, cadastro de pacientes e abertura de atendimentos'),
(2, 'Pronto-Socorro', 'Atendimento médico de urgência e emergência'),
(3, 'Enfermagem', 'Triagem com classificação de risco e assistência de enfermagem'),
(4, 'UTI', 'Unidade de terapia intensiva para pacientes críticos'),
(5, 'Internação', 'Enfermarias de internação clínica e cirúrgica'),
(6, 'Laboratório', 'Coleta e análise de exames laboratoriais'),
(7, 'Diagnóstico por Imagem', 'Exames de raio-X, tomografia e ultrassonografia'),
(8, 'Farmácia', 'Dispensação e controle de medicamentos'),
(9, 'Almoxarifado', 'Recebimento e controle de materiais médico-hospitalares'),
(10, 'Administração', 'Direção, gestão de pessoas e tecnologia da informação');

select * from setor;
