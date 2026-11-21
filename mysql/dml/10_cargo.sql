use gestao_emergencia_hospitalar;
set names utf8mb4;

insert into cargo (id_cargo, id_setor, nome, descricao) values
(1, 1, 'Recepcionista', 'Recebe o paciente, confere documentos, faz o cadastro e abre o atendimento'),
(2, 1, 'Coordenador de recepção', 'Organiza escalas e o fluxo de pacientes da recepção'),
(3, 2, 'Médico plantonista clínico', 'Atendimento clínico de urgência e emergência no pronto-socorro'),
(4, 2, 'Médico ortopedista', 'Atendimento de traumas, fraturas e lesões ortopédicas'),
(5, 2, 'Médico pediatra', 'Atendimento de urgência a crianças e adolescentes'),
(6, 2, 'Médico cirurgião geral', 'Avaliação cirúrgica e cirurgias de urgência'),
(7, 3, 'Enfermeiro', 'Triagem com classificação de risco e supervisão da assistência de enfermagem'),
(8, 3, 'Técnico de enfermagem', 'Aferição de sinais vitais, administração de medicamentos e cuidados ao paciente'),
(9, 3, 'Enfermeiro coordenador', 'Coordena a equipe de enfermagem e a gestão de leitos'),
(10, 4, 'Médico intensivista', 'Assistência a pacientes críticos internados na UTI'),
(11, 4, 'Enfermeiro intensivista', 'Assistência de enfermagem ao paciente crítico'),
(12, 5, 'Médico hospitalista', 'Acompanhamento dos pacientes internados nas enfermarias'),
(13, 6, 'Biomédico', 'Análise de amostras e liberação de laudos laboratoriais'),
(14, 6, 'Técnico de laboratório', 'Coleta e preparo de amostras biológicas'),
(15, 7, 'Médico radiologista', 'Emissão de laudos de exames de imagem'),
(16, 7, 'Técnico em radiologia', 'Realização de exames de raio-X e tomografia'),
(17, 8, 'Farmacêutico', 'Controle de medicamentos, dispensação e gestão do estoque da farmácia'),
(18, 8, 'Auxiliar de farmácia', 'Separação e dispensação de medicamentos e materiais'),
(19, 9, 'Almoxarife', 'Recebimento, guarda e controle dos materiais do almoxarifado'),
(20, 10, 'Diretor clínico', 'Responsável técnico pela assistência médica do hospital'),
(21, 10, 'Analista administrativo', 'Gestão de cadastros, relatórios, equipamentos e acessos ao sistema');

select * from cargo;
