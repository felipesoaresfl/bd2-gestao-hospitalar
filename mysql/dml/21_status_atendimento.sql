-- =====================================================================
-- Sistema de Gestão de Emergências e Atendimento Hospitalar
-- Carga de dados - Tabela: STATUS_ATENDIMENTO
-- Ordem de execução: 21 de 37
-- Registros: 8
-- Etapas do atendimento.
-- =====================================================================
-- Obs.: os IDs são informados explicitamente para garantir que as
-- chaves estrangeiras dos próximos arquivos apontem para o registro certo.

use gestao_emergencia_hospitalar;
set names utf8mb4;

insert into status_atendimento (id_status, descricao) values
(1, 'Aguardando triagem'),
(2, 'Aguardando atendimento médico'),
(3, 'Em atendimento médico'),
(4, 'Aguardando resultado de exames'),
(5, 'Em observação'),
(6, 'Internado'),
(7, 'Aguardando transferência'),
(8, 'Finalizado');

-- Conferência
select * from status_atendimento;
