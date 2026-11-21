use gestao_emergencia_hospitalar;
set names utf8mb4;

insert into estoque (id_estoque, nome, descricao) values
(1, 'Farmácia central', 'Estoque principal de medicamentos do hospital'),
(2, 'Farmácia satélite do pronto-socorro', 'Medicamentos dispensados para os atendimentos do pronto-socorro'),
(3, 'Farmácia satélite da UTI', 'Medicamentos de uso na UTI adulto e coronariana'),
(4, 'Almoxarifado central', 'Estoque principal de materiais médico-hospitalares'),
(5, 'Almoxarifado do pronto-socorro', 'Materiais dispensados para os atendimentos do pronto-socorro');

select * from estoque;
