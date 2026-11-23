use("gestao_emergencia_hospitalar");

var indices = {
  telemetria_sinais_vitais: [
    "idx_telem_tipolocal_spo2_ts_fc",
    "idx_telem_alerta_sev_cod_ts",
    "idx_telem_identificado_bateria_ts"
  ],
  logs_auditoria: [
    "idx_log_acao_tags_ts",
    "idx_log_acao_sucesso_ts",
    "idx_log_acao_ts_modulo_setor"
  ],
  intercorrencias_atendimento: [
    "idx_interc_resolucao_data",
    "idx_interc_tags_data_categoria",
    "idx_interc_paciente_data",
    "uq_interc_codigo"
  ],
  linha_tempo_atendimento: [
    "idx_lt_encerr_prio_entrada_eventos",
    "idx_lt_evtipo_situacao_total_entrada",
    "idx_lt_prio_entrada",
    "uq_lt_id_atendimento"
  ]
};

Object.keys(indices).forEach(function (colecao) {
  indices[colecao].forEach(function (nome) {
    try {
      db.getCollection(colecao).dropIndex(nome);
      print("removido  " + colecao + " -> " + nome);
    } catch (e) {
      print("ignorado  " + colecao + " -> " + nome + " (não existe)");
    }
  });
});