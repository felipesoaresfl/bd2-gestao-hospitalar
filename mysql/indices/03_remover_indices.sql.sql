USE gestao_emergencia_hospitalar;

DROP INDEX idx_atendimento_paciente_entrada ON atendimento;
DROP INDEX idx_atendimento_entrada_tipo     ON atendimento;
DROP INDEX idx_triagem_class_atend_data     ON triagem;
DROP INDEX idx_alta_tipo_cid_atend          ON alta;
DROP INDEX idx_internacao_status_tipo_datas ON internacao;
DROP INDEX idx_movest_insumo_tipo_solic_qtd ON movimentacao_estoque;
DROP INDEX idx_alergia_tipo_grav_hist       ON alergia;
DROP INDEX idx_sinais_data_alerta           ON sinais_vitais;
DROP INDEX idx_solicitacao_prio_exame_data  ON solicitacao;
DROP INDEX idx_resultado_solic_sit_data     ON resultado_exame;