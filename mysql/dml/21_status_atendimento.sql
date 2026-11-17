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

select * from status_atendimento;
