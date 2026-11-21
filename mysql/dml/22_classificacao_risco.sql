use gestao_emergencia_hospitalar;
set names utf8mb4;

insert into classificacao_risco (id_classificacao, cor, descricao, tempo_max_espera, prioridade) values
(1, 'Vermelho', 'Emergência', 0, 1),
(2, 'Laranja', 'Muito urgente', 10, 2),
(3, 'Amarelo', 'Urgente', 60, 3),
(4, 'Verde', 'Pouco urgente', 120, 4),
(5, 'Azul', 'Não urgente', 240, 5);

select * from classificacao_risco;
