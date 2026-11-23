use("gestao_emergencia_hospitalar");

function criar(colecao, chaves, nome) {
  try {
    const criado = db.getCollection(colecao).createIndex(chaves, { name: nome });
    print("OK   " + colecao + " -> " + criado);
  } catch (e) {
    print("ERRO " + colecao + " -> " + nome + ": " + e.message);
  }
}

// ===== telemetria_sinais_vitais =====
criar("telemetria_sinais_vitais",
  { "localizacao.tipo_local": 1, "sinais.saturacao_o2_pct": 1, "timestamp": -1, "sinais.frequencia_cardiaca_bpm": 1 },
  "idx_telem_tipolocal_spo2_ts_fc");

criar("telemetria_sinais_vitais",
  { "alertas_disparados.severidade": 1, "alertas_disparados.codigo": 1, "timestamp": -1 },
  "idx_telem_alerta_sev_cod_ts");

criar("telemetria_sinais_vitais",
  { "paciente_ref.identificado": 1, "dispositivo.bateria_pct": 1, "timestamp": -1 },
  "idx_telem_identificado_bateria_ts");

// ===== logs_auditoria =====
criar("logs_auditoria",
  { "acao": 1, "tags": 1, "timestamp": -1 },
  "idx_log_acao_tags_ts");

criar("logs_auditoria",
  { "acao": 1, "contexto_acesso.sucesso": 1, "timestamp": -1 },
  "idx_log_acao_sucesso_ts");

criar("logs_auditoria",
  { "acao": 1, "timestamp": -1, "modulo": 1, "usuario.setor": 1 },
  "idx_log_acao_ts_modulo_setor");

// ===== intercorrencias_atendimento =====
criar("intercorrencias_atendimento",
  { "data_hora_resolucao": 1, "data_hora": -1 },
  "idx_interc_resolucao_data");

criar("intercorrencias_atendimento",
  { "tags": 1, "data_hora": -1, "categoria": 1 },
  "idx_interc_tags_data_categoria");

criar("intercorrencias_atendimento",
  { "id_paciente": 1, "data_hora": -1 },
  "idx_interc_paciente_data");

// ===== linha_tempo_atendimento =====
criar("linha_tempo_atendimento",
  { "data_hora_encerramento": 1, "classificacao_risco.prioridade": 1, "data_hora_entrada": 1, "total_eventos": 1 },
  "idx_lt_encerr_prio_entrada_eventos");

criar("linha_tempo_atendimento",
  { "eventos.tipo": 1, "eventos.detalhes.situacao": 1, "total_eventos": -1, "data_hora_entrada": -1 },
  "idx_lt_evtipo_situacao_total_entrada");

criar("linha_tempo_atendimento",
  { "classificacao_risco.prioridade": 1, "data_hora_entrada": -1 },
  "idx_lt_prio_entrada");

// ===== Índices únicos (integridade + $lookup do item 3.6) =====
try {
  const r1 = db.intercorrencias_atendimento.createIndex(
    { "codigo_intercorrencia": 1 }, { unique: true, name: "uq_interc_codigo" });
  print("OK   intercorrencias_atendimento -> " + r1);
  const r2 = db.linha_tempo_atendimento.createIndex(
    { "id_atendimento": 1 }, { unique: true, name: "uq_lt_id_atendimento" });
  print("OK   linha_tempo_atendimento -> " + r2);
} catch (e) {
  print("ERRO nos índices únicos: " + e.message);
}

// ===== Conferência =====
["telemetria_sinais_vitais", "logs_auditoria", "intercorrencias_atendimento", "linha_tempo_atendimento"]
  .forEach(function (c) {
    print("\n" + c);
    db.getCollection(c).getIndexes().forEach(function (i) {
      print("  " + i.name + "  " + JSON.stringify(i.key) + (i.unique ? "  [unique]" : ""));
    });
  });