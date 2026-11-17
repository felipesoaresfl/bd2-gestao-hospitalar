-- =====================================================================
-- Sistema de Gestão de Emergências e Atendimento Hospitalar
-- Carga de dados - Tabela: ESTOQUE
-- Ordem de execução: 30 de 37
-- Registros: 5
-- Locais de armazenamento; o saldo vem das movimentações.
-- =====================================================================
-- Obs.: os IDs são informados explicitamente para garantir que as
-- chaves estrangeiras dos próximos arquivos apontem para o registro certo.

use gestao_emergencia_hospitalar;
set names utf8mb4;

insert into estoque (id_estoque, nome, descricao) values
(1, 'Farmácia central', 'Estoque principal de medicamentos do hospital'),
(2, 'Farmácia satélite do pronto-socorro', 'Medicamentos dispensados para os atendimentos do pronto-socorro'),
(3, 'Farmácia satélite da UTI', 'Medicamentos de uso na UTI adulto e coronariana'),
(4, 'Almoxarifado central', 'Estoque principal de materiais médico-hospitalares'),
(5, 'Almoxarifado do pronto-socorro', 'Materiais dispensados para os atendimentos do pronto-socorro');

-- Conferência
select * from estoque;
