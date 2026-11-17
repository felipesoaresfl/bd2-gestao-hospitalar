-- =====================================================================
-- Sistema de Gestão de Emergências e Atendimento Hospitalar
-- Carga de dados - Tabela: CLASSIFICACAO_RISCO
-- Ordem de execução: 22 de 37
-- Registros: 5
-- Protocolo de Manchester (tempo em minutos).
-- =====================================================================
-- Obs.: os IDs são informados explicitamente para garantir que as
-- chaves estrangeiras dos próximos arquivos apontem para o registro certo.

use gestao_emergencia_hospitalar;
set names utf8mb4;

insert into classificacao_risco (id_classificacao, cor, descricao, tempo_max_espera, prioridade) values
(1, 'Vermelho', 'Emergência', 0, 1),
(2, 'Laranja', 'Muito urgente', 10, 2),
(3, 'Amarelo', 'Urgente', 60, 3),
(4, 'Verde', 'Pouco urgente', 120, 4),
(5, 'Azul', 'Não urgente', 240, 5);

-- Conferência
select * from classificacao_risco;
