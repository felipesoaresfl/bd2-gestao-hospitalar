use("gestao_emergencia_hospitalar");

db.telemetria_sinais_vitais.insertOne({
  id_atendimento: 2128,
  paciente_ref: { id_paciente: 1305, id_cadastro_provisorio: null, identificado: true },
  dispositivo: { id_equipamento: 178, numero_patrimonio: "PAT-2020-00178", modelo: "Monitor multiparamétrico MP-12", bateria_pct: 92 },
  localizacao: { id_local: 43, nome_local: "UTI adulto", tipo_local: "U", id_leito: 59, numero_leito: "UTI-10" },
  timestamp: ISODate("2026-11-16T13:10:00Z"),
  sinais: {
    frequencia_cardiaca_bpm: 98,
    frequencia_respiratoria_irpm: 20,
    pressao_arterial: { sistolica_mmhg: 104, diastolica_mmhg: 62 },
    saturacao_o2_pct: 95,
    temperatura_c: 37.6
  },
  alertas_disparados: [],
  qualidade_sinal: "OK"
});

db.telemetria_sinais_vitais.insertMany([
  {
    id_atendimento: 2128,
    paciente_ref: { id_paciente: 1305, id_cadastro_provisorio: null, identificado: true },
    dispositivo: { id_equipamento: 178, numero_patrimonio: "PAT-2020-00178", modelo: "Monitor multiparamétrico MP-12", bateria_pct: 92 },
    localizacao: { id_local: 43, nome_local: "UTI adulto", tipo_local: "U", id_leito: 59, numero_leito: "UTI-10" },
    timestamp: ISODate("2026-11-16T13:15:00Z"),
    sinais: {
      frequencia_cardiaca_bpm: 109,
      frequencia_respiratoria_irpm: 22,
      pressao_arterial: { sistolica_mmhg: 88, diastolica_mmhg: 54 },
      saturacao_o2_pct: 94,
      temperatura_c: 38.1
    },
    alertas_disparados: [
      { codigo: "TAQUICARDIA", severidade: "BAIXA", valor_medido: 109, limite_referencia: 100 },
      { codigo: "HIPOTENSAO", severidade: "MEDIA", valor_medido: 88, limite_referencia: 90 },
      { codigo: "FEBRE", severidade: "BAIXA", valor_medido: 38.1, limite_referencia: 37.8 }
    ],
    qualidade_sinal: "OK"
  },
  {
    id_atendimento: 2128,
    paciente_ref: { id_paciente: 1305, id_cadastro_provisorio: null, identificado: true },
    dispositivo: { id_equipamento: 178, numero_patrimonio: "PAT-2020-00178", modelo: "Monitor multiparamétrico MP-12", bateria_pct: 91 },
    localizacao: { id_local: 43, nome_local: "UTI adulto", tipo_local: "U", id_leito: 59, numero_leito: "UTI-10" },
    timestamp: ISODate("2026-11-16T13:20:00Z"),
    sinais: {
      frequencia_cardiaca_bpm: 118,
      frequencia_respiratoria_irpm: 24,
      pressao_arterial: { sistolica_mmhg: 82, diastolica_mmhg: 50 },
      saturacao_o2_pct: null,
      temperatura_c: 38.4
    },
    alertas_disparados: [
      { codigo: "TAQUICARDIA", severidade: "MEDIA", valor_medido: 118, limite_referencia: 100 },
      { codigo: "HIPOTENSAO", severidade: "MEDIA", valor_medido: 82, limite_referencia: 90 },
      { codigo: "FEBRE", severidade: "BAIXA", valor_medido: 38.4, limite_referencia: 37.8 }
    ],
    qualidade_sinal: "SEM_SINAL_SPO2"
  },
  {
    id_atendimento: 2128,
    paciente_ref: { id_paciente: 1305, id_cadastro_provisorio: null, identificado: true },
    dispositivo: { id_equipamento: 178, numero_patrimonio: "PAT-2020-00178", modelo: "Monitor multiparamétrico MP-12", bateria_pct: 91 },
    localizacao: { id_local: 43, nome_local: "UTI adulto", tipo_local: "U", id_leito: 59, numero_leito: "UTI-10" },
    timestamp: ISODate("2026-11-16T13:25:00Z"),
    sinais: {
      frequencia_cardiaca_bpm: 124,
      frequencia_respiratoria_irpm: 26,
      pressao_arterial: { sistolica_mmhg: 78, diastolica_mmhg: 46 },
      saturacao_o2_pct: 91,
      temperatura_c: 38.6
    },
    alertas_disparados: [
      { codigo: "HIPOXEMIA", severidade: "BAIXA", valor_medido: 91, limite_referencia: 92 },
      { codigo: "TAQUICARDIA", severidade: "MEDIA", valor_medido: 124, limite_referencia: 100 },
      { codigo: "HIPOTENSAO", severidade: "ALTA", valor_medido: 78, limite_referencia: 90 },
      { codigo: "TAQUIPNEIA", severidade: "MEDIA", valor_medido: 26, limite_referencia: 24 },
      { codigo: "FEBRE", severidade: "MEDIA", valor_medido: 38.6, limite_referencia: 37.8 }
    ],
    qualidade_sinal: "OK"
  }
]);

db.intercorrencias_atendimento.insertOne({
  codigo_intercorrencia: "INT-2026-001420",
  id_atendimento: 2128,
  id_paciente: 1305,
  id_cadastro_provisorio: null,
  id_local: 43,
  data_hora: ISODate("2026-11-16T13:26:00Z"),
  categoria: "HEMODINAMICA",
  gravidade: "ALTA",
  status: "ABERTA",
  descricao: "Queda da pressão arterial para 78x46 mmHg com taquicardia e febre, em paciente com sepse.",
  responsavel: { id_funcionario: 76, login: "danilo.pereira", cargo: "Médico intensivista" },
  medidas_adotadas: [
    { ordem: 1, acao: "Expansão volêmica com SF 0,9% 500 mL", hora: ISODate("2026-11-16T13:27:00Z"), executado_por_id_funcionario: 185 },
    { ordem: 2, acao: "Coleta de lactato arterial", hora: ISODate("2026-11-16T13:28:00Z"), executado_por_id_funcionario: 185 }
  ],
  data_hora_resolucao: null,
  tags: ["hipotensao", "instabilidade_hemodinamica", "uti"]
});

db.intercorrencias_atendimento.insertMany([
  {
    codigo_intercorrencia: "INT-TESTE-0001",
    id_atendimento: 2128,
    id_paciente: 1305,
    id_cadastro_provisorio: null,
    id_local: 43,
    data_hora: ISODate("2026-11-16T13:30:00Z"),
    categoria: "QUEDA",
    gravidade: "BAIXA",
    status: "ABERTA",
    descricao: "Registro de teste criado no treinamento da equipe de enfermagem.",
    responsavel: { id_funcionario: 185, login: "luciana.morais", cargo: "Enfermeiro intensivista" },
    medidas_adotadas: [],
    data_hora_resolucao: null,
    rascunho: true,
    tags: ["teste_exclusao"]
  },
  {
    codigo_intercorrencia: "INT-TESTE-0002",
    id_atendimento: 2128,
    id_paciente: 1305,
    id_cadastro_provisorio: null,
    id_local: 43,
    data_hora: ISODate("2026-11-16T13:30:00Z"),
    categoria: "ACESSO_VENOSO",
    gravidade: "BAIXA",
    status: "ABERTA",
    descricao: "Registro de teste criado no treinamento da equipe de enfermagem.",
    responsavel: { id_funcionario: 185, login: "luciana.morais", cargo: "Enfermeiro intensivista" },
    data_hora_resolucao: null,
    rascunho: true,
    tags: ["teste_exclusao", "treinamento"]
  }
]);

db.logs_auditoria.insertMany([
  {
    timestamp: ISODate("2026-11-16T13:05:00Z"),
    usuario: { id_funcionario: 76, login: "danilo.pereira", cargo: "Médico intensivista", setor: "UTI" },
    acao: "LOGIN",
    modulo: "AUTENTICACAO",
    entidade: { tabela: "funcionario", registro_id: 76 },
    contexto_acesso: { ip: "10.20.4.86", estacao: "UTI-TERM-02", sucesso: true },
    tags: ["autenticacao"],
    hash_anterior: "0b8ca0f2db5f3b6fcd3158f3b78367050e55b6e4554b879351ad5a731f465697",
    hash_registro: "6471bc85653500713e9f4e940e40a600a1152a25c7842b3a682e1912177cc465"
  },
  {
    timestamp: ISODate("2026-11-16T13:08:00Z"),
    usuario: { id_funcionario: 76, login: "danilo.pereira", cargo: "Médico intensivista", setor: "UTI" },
    acao: "SELECT",
    modulo: "EXAMES",
    entidade: { tabela: "resultado_exame", registro_id: 4516 },
    alteracoes: null,
    contexto_acesso: { ip: "10.20.4.86", estacao: "UTI-TERM-02", sucesso: true },
    tags: ["laudo", "dado_sensivel"],
    hash_anterior: "6471bc85653500713e9f4e940e40a600a1152a25c7842b3a682e1912177cc465",
    hash_registro: "6934287a27b106fe2af7e34c6e3e036b2d31ad72e07cf120c3a051b7da63787e"
  },
  {
    timestamp: ISODate("2026-11-16T13:09:00Z"),
    usuario: { id_funcionario: 76, login: "danilo.pereira", cargo: "Médico intensivista", setor: "UTI" },
    acao: "SELECT",
    modulo: "INTERNACAO",
    entidade: { tabela: "internacao", registro_id: 314 },
    contexto_acesso: { ip: "10.20.4.86", estacao: "UTI-TERM-02", sucesso: true },
    tags: ["internacao"],
    hash_anterior: "6934287a27b106fe2af7e34c6e3e036b2d31ad72e07cf120c3a051b7da63787e",
    hash_registro: "6dddff497b9e76e382ab0cac714e665b5ea0347d1ab62447b04f0afa3d9f6bf2"
  }
]);

db.logs_auditoria.insertOne({
  timestamp: ISODate("2026-11-16T13:12:00Z"),
  usuario: { id_funcionario: 76, login: "danilo.pereira", cargo: "Médico intensivista", setor: "UTI" },
  acao: "SELECT",
  modulo: "PRONTUARIO",
  entidade: { tabela: "historico_clinico", registro_id: 1305 },
  contexto_acesso: { ip: "10.20.4.86", estacao: "UTI-TERM-02", sucesso: true },
  tags: ["dado_sensivel", "lgpd", "prontuario"],
  hash_anterior: "6dddff497b9e76e382ab0cac714e665b5ea0347d1ab62447b04f0afa3d9f6bf2",
  hash_registro: "18b7189221e1f03fdce4596ca837fab395cc824be41d548b595b94c63bbf8df4"
});

db.linha_tempo_atendimento.insertOne({
  id_atendimento: 2201,
  paciente_ref: { id_paciente: 1801, id_cadastro_provisorio: null },
  classificacao_risco: { cor: "Amarelo", prioridade: 3 },
  status_atual: "Aguardando atendimento médico",
  queixa_principal: "Dor no peito em pontada que piora ao respirar fundo",
  local_atual: { id_local: 1, nome: "Recepção principal" },
  data_hora_entrada: ISODate("2026-11-16T13:20:00Z"),
  data_hora_encerramento: null,
  total_eventos: 3,
  eventos: [
    {
      tipo: "ENTRADA",
      data_hora: ISODate("2026-11-16T13:20:00Z"),
      id_funcionario: 17,
      resumo: "Abertura de atendimento (Espontânea) - Queixa: Dor no peito em pontada que piora ao respirar fundo",
      detalhes: { tipo_entrada: "E", id_local: 1 }
    },
    {
      tipo: "TRIAGEM",
      data_hora: ISODate("2026-11-16T13:28:00Z"),
      id_funcionario: 1,
      resumo: "Classificação Amarelo (Urgente)",
      detalhes: { id_triagem: 2199, cor: "Amarelo" }
    },
    {
      tipo: "SINAIS_VITAIS",
      data_hora: ISODate("2026-11-16T13:28:00Z"),
      id_funcionario: 1,
      resumo: "PA 132x84, FC 92, SpO2 97%",
      detalhes: { id_sinais_vitais: 5989 }
    }
  ]
});

db.telemetria_sinais_vitais.countDocuments();
db.logs_auditoria.countDocuments();
db.intercorrencias_atendimento.countDocuments();
db.linha_tempo_atendimento.countDocuments();
