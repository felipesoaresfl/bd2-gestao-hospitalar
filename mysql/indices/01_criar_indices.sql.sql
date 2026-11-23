USE gestao_emergencia_hospitalar;

-- Consultas 06, 09 e 11: agrupamento/junção por paciente e ordenação/MIN/MAX por entrada
CREATE INDEX idx_atendimento_paciente_entrada
  ON atendimento (id_paciente, data_hora_entrada);

-- Consulta 01: índice de cobertura para contagem mensal por tipo de chegada
CREATE INDEX idx_atendimento_entrada_tipo
  ON atendimento (data_hora_entrada, tipo_entrada);

-- Consultas 02 e 09: junção com classificação de risco + cálculo de espera até triagem
CREATE INDEX idx_triagem_class_atend_data
  ON triagem (id_classificacao, id_atendimento, data_hora);

-- Consulta 04: filtro por tipo de alta ('M') + agrupamento por cid_final + junção
CREATE INDEX idx_alta_tipo_cid_atend
  ON alta (tipo, cid_final, id_atendimento);

-- Consulta 07: filtro por internações encerradas ('E') + agrupamento por tipo + datas
CREATE INDEX idx_internacao_status_tipo_datas
  ON internacao (status, tipo, data_hora_entrada, data_hora_saida);

-- Consulta 08: saldo por insumo (subconsulta) e consumo de saídas vinculadas a solicitação
CREATE INDEX idx_movest_insumo_tipo_solic_qtd
  ON movimentacao_estoque (id_insumo, tipo, id_solicitacao, quantidade);

-- Consulta 09: filtro por alergia medicamentosa ('M') moderada/grave ('M','G')
CREATE INDEX idx_alergia_tipo_grav_hist
  ON alergia (tipo, gravidade, id_historico);

-- Consulta 10: leitura reversa por data_hora com filtro OR de alerta dentro do índice (LIMIT 30)
CREATE INDEX idx_sinais_data_alerta
  ON sinais_vitais (data_hora, saturacao_o2, pressao_sistolica, temperatura, id_atendimento);

-- Consulta 12: filtro por solicitações urgentes ('U') + junção com exame + data_hora
CREATE INDEX idx_solicitacao_prio_exame_data
  ON solicitacao (prioridade, id_exame, data_hora);

-- Consultas 05 e 12: cobertura para situação e data do laudo sem ler o campo TEXT
CREATE INDEX idx_resultado_solic_sit_data
  ON resultado_exame (id_solicitacao, situacao, data_hora_resultado);

ANALYZE TABLE atendimento, triagem, alta, internacao, sinais_vitais, solicitacao,
              resultado_exame, movimentacao_estoque, alergia;

-- Conferência dos índices criados (guarde os prints)
SHOW INDEX FROM atendimento;
SHOW INDEX FROM triagem;
SHOW INDEX FROM alta;
SHOW INDEX FROM internacao;
SHOW INDEX FROM movimentacao_estoque;
SHOW INDEX FROM alergia;
SHOW INDEX FROM sinais_vitais;
SHOW INDEX FROM solicitacao;
SHOW INDEX FROM resultado_exame;