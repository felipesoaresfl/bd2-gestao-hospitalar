-- =====================================================================
-- Sistema de Gestão de Emergências e Atendimento Hospitalar
-- Carga de dados - Tabela: TIPO_EXAME
-- Ordem de execução: 27 de 37
-- Registros: 6
-- Categorias de exame.
-- =====================================================================
-- Obs.: os IDs são informados explicitamente para garantir que as
-- chaves estrangeiras dos próximos arquivos apontem para o registro certo.

use gestao_emergencia_hospitalar;
set names utf8mb4;

insert into tipo_exame (id_tipo_exame, nome) values
(1, 'Laboratorial'),
(2, 'Imagem'),
(3, 'Cardiológico'),
(4, 'Microbiológico'),
(5, 'Urinálise'),
(6, 'Teste rápido');

-- Conferência
select * from tipo_exame;
