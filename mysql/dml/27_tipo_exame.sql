use gestao_emergencia_hospitalar;
set names utf8mb4;

insert into tipo_exame (id_tipo_exame, nome) values
(1, 'Laboratorial'),
(2, 'Imagem'),
(3, 'Cardiológico'),
(4, 'Microbiológico'),
(5, 'Urinálise'),
(6, 'Teste rápido');

select * from tipo_exame;
