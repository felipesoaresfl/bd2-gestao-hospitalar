-- =====================================================================
-- Sistema de Gestão de Emergências e Atendimento Hospitalar
-- Carga de dados - Tabela: CONVENIO
-- Ordem de execução: 01 de 37
-- Registros: 15
-- 15 convênios (13 ativos, 2 inativos).
-- =====================================================================
-- Obs.: os IDs são informados explicitamente para garantir que as
-- chaves estrangeiras dos próximos arquivos apontem para o registro certo.

use gestao_emergencia_hospitalar;
set names utf8mb4;

insert into convenio (id_convenio, nome, registro_ans, telefone, status) values
(1, 'Unimed São José dos Campos', '335690', '1239041000', 'A'),
(2, 'Bradesco Saúde', '005711', '08007012700', 'A'),
(3, 'SulAmérica Saúde', '006246', '08000178700', 'A'),
(4, 'Amil Assistência Médica', '326305', '08000210404', 'A'),
(5, 'Porto Seguro Saúde', '000582', '08007272222', 'A'),
(6, 'NotreDame Intermédica', '359017', '08000155544', 'A'),
(7, 'Hapvida Saúde', '368253', '08002800000', 'A'),
(8, 'Cassi - Caixa de Assistência dos Funcionários do BB', '346659', '08007290080', 'A'),
(9, 'Saúde Caixa', '417220', '08000951111', 'A'),
(10, 'Cabesp', '324477', '08007724404', 'A'),
(11, 'Unimed Taubaté', '334855', '1236254000', 'A'),
(12, 'Allianz Saúde', '000515', '08007228148', 'A'),
(13, 'Care Plus', '379956', '08000171515', 'A'),
(14, 'Golden Cross', '403911', '08007282001', 'I'),
(15, 'Prevent Senior', '302147', '08000177070', 'I');

-- Conferência
select * from convenio;
