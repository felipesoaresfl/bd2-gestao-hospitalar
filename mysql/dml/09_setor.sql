-- =====================================================================
-- Sistema de Gestão de Emergências e Atendimento Hospitalar
-- Carga de dados - Tabela: SETOR
-- Ordem de execução: 09 de 37
-- Registros: 10
-- 10 setores do hospital.
-- =====================================================================
-- Obs.: os IDs são informados explicitamente para garantir que as
-- chaves estrangeiras dos próximos arquivos apontem para o registro certo.

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

-- Conferência
select * from setor;
