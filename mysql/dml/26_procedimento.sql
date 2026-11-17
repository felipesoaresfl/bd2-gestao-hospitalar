-- =====================================================================
-- Sistema de Gestão de Emergências e Atendimento Hospitalar
-- Carga de dados - Tabela: PROCEDIMENTO
-- Ordem de execução: 26 de 37
-- Registros: 40
-- Catálogo de procedimentos (código no formato SIGTAP, valores de referência).
-- =====================================================================
-- Obs.: os IDs são informados explicitamente para garantir que as
-- chaves estrangeiras dos próximos arquivos apontem para o registro certo.

use gestao_emergencia_hospitalar;
set names utf8mb4;

insert into procedimento (id_procedimento, codigo, nome, descricao, valor) values
(1, '0301060029', 'Atendimento de urgência com observação até 24 horas', 'Permanência do paciente em observação no pronto-socorro', 62.80),
(2, '0408424614', 'Curativo grau I', 'Limpeza e cobertura de ferimento simples', 18.50),
(3, '0401010023', 'Curativo grau II com desbridamento', 'Curativo de ferida complexa com retirada de tecido desvitalizado', 45.20),
(4, '0401463261', 'Sutura simples de ferimento até 5 cm', 'Limpeza, anestesia local e sutura de ferimento pequeno', 38.70),
(5, '0301549894', 'Sutura de ferimento extenso (acima de 5 cm)', 'Sutura em planos de ferimento extenso', 86.40),
(6, '0401212460', 'Imobilização provisória de membro', 'Imobilização com tala para transporte ou alívio da dor', 24.00),
(7, '0406192417', 'Imobilização com tala gessada', 'Confecção de tala ou aparelho gessado', 55.00),
(8, '0303765252', 'Redução incruenta de fratura', 'Redução manual da fratura sob analgesia', 120.00),
(9, '0301628383', 'Redução de luxação', 'Recolocação articular sob analgesia ou sedação', 110.00),
(10, '0401080826', 'Enfaixamento compressivo', 'Enfaixamento de articulação com atadura de crepe', 15.00),
(11, '0301165332', 'Retirada de corpo estranho de pele e subcutâneo', 'Remoção de corpo estranho superficial', 42.00),
(12, '0301632952', 'Retirada de corpo estranho de ouvido ou nariz', 'Remoção de corpo estranho em cavidade', 35.00),
(13, '0406408472', 'Drenagem de abscesso', 'Incisão e drenagem de abscesso cutâneo', 58.00),
(14, '0406471415', 'Nebulização / inalação', 'Administração de medicação inalatória', 9.80),
(15, '0401761918', 'Oxigenoterapia', 'Administração de oxigênio por cateter nasal ou máscara', 12.30),
(16, '0408481720', 'Aspiração de vias aéreas superiores', 'Aspiração de secreções nasais e orofaríngeas', 10.50),
(17, '0401320576', 'Intubação orotraqueal', 'Garantia de via aérea definitiva', 180.00),
(18, '0406372759', 'Ventilação mecânica invasiva (diária)', 'Suporte ventilatório invasivo por 24 horas', 310.00),
(19, '0303046923', 'Cardioversão elétrica', 'Reversão de arritmia com choque sincronizado', 150.00),
(20, '0406210272', 'Reanimação cardiopulmonar', 'Manobras de suporte avançado de vida', 200.00),
(21, '0406456812', 'Acesso venoso central', 'Punção de veia central guiada por ultrassom', 145.00),
(22, '0303748129', 'Punção arterial para gasometria', 'Coleta de sangue arterial', 14.00),
(23, '0406193167', 'Sondagem vesical de demora', 'Passagem de sonda vesical com sistema fechado', 28.00),
(24, '0406380662', 'Sondagem vesical de alívio', 'Esvaziamento vesical com sonda', 18.00),
(25, '0406838749', 'Sondagem nasogástrica', 'Passagem de sonda nasogástrica', 26.00),
(26, '0406261256', 'Lavagem gástrica', 'Lavagem gástrica em intoxicação exógena', 48.00),
(27, '0401091377', 'Hidratação venosa', 'Reposição volêmica endovenosa', 20.00),
(28, '0303930665', 'Monitorização cardíaca contínua', 'Monitorização de ECG, pressão e saturação', 35.00),
(29, '0406150786', 'Drenagem torácica (toracostomia)', 'Inserção de dreno de tórax em selo d’água', 260.00),
(30, '0406704397', 'Toracocentese', 'Punção de derrame pleural', 130.00),
(31, '0401171840', 'Paracentese', 'Punção de líquido ascítico', 120.00),
(32, '0401282551', 'Punção lombar', 'Coleta de líquor', 140.00),
(33, '0401362108', 'Cantoplastia ungueal', 'Tratamento cirúrgico de unha encravada', 65.00),
(34, '0406484750', 'Lavagem ocular', 'Irrigação ocular com soro fisiológico', 12.00),
(35, '0303579927', 'Tamponamento nasal anterior', 'Controle de epistaxe', 40.00),
(36, '0401231268', 'Retirada de pontos', 'Remoção de fios de sutura', 10.00),
(37, '0303522696', 'Aplicação de vacina antitetânica (dT)', 'Profilaxia do tétano em ferimentos', 8.00),
(38, '0401392716', 'Glicemia capilar', 'Medida da glicose com glicosímetro', 4.50),
(39, '0401548370', 'Desbridamento de ferida', 'Retirada de tecido necrótico', 75.00),
(40, '0303370302', 'Curativo de queimadura', 'Limpeza e curativo de queimadura de pequena extensão', 32.00);

-- Conferência
select * from procedimento;
