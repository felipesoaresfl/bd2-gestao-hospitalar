use("gestao_emergencia_hospitalar");

// Consulta 01
print("\n=== Consulta 01 ===");
printjson(
  db.telemetria_sinais_vitais.find(
    {
      "localizacao.tipo_local": "U",
      "sinais.saturacao_o2_pct": { $lt: 90 },
      "sinais.frequencia_cardiaca_bpm": { $gt: 110 }
    },
    {
      _id: 0,
      id_atendimento: 1,
      timestamp: 1,
      "localizacao.nome_local": 1,
      "localizacao.numero_leito": 1,
      "sinais.saturacao_o2_pct": 1,
      "sinais.frequencia_cardiaca_bpm": 1,
      "sinais.pressao_arterial": 1,
      alertas_disparados: 1
    }
  )
  .sort({ "sinais.saturacao_o2_pct": 1, timestamp: -1 })
  .limit(10)
  .toArray()
);

// Consulta 02
print("\n=== Consulta 02 ===");
printjson(
  db.telemetria_sinais_vitais.find(
    {
      timestamp: {
        $gte: ISODate("2026-10-01T00:00:00Z"),
        $lte: ISODate("2026-11-30T23:59:59Z")
      },
      alertas_disparados: {
        $elemMatch: {
          codigo: { $in: ["HIPOXEMIA", "HIPOTENSAO"] },
          severidade: "CRITICA"
        }
      }
    },
    {
      _id: 0,
      id_atendimento: 1,
      timestamp: 1,
      "dispositivo.numero_patrimonio": 1,
      "localizacao.nome_local": 1,
      "localizacao.numero_leito": 1,
      alertas_disparados: 1
    }
  )
  .sort({ timestamp: -1 })
  .limit(10)
  .toArray()
);

// Consulta 03
print("\n=== Consulta 03 ===");
printjson(
  db.telemetria_sinais_vitais.find(
    {
      "paciente_ref.identificado": false,
      $or: [
        { qualidade_sinal: { $ne: "OK" } },
        { "dispositivo.bateria_pct": { $lte: 75 } }
      ]
    },
    {
      _id: 0,
      id_atendimento: 1,
      "paciente_ref.id_cadastro_provisorio": 1,
      timestamp: 1,
      qualidade_sinal: 1,
      "dispositivo.numero_patrimonio": 1,
      "dispositivo.modelo": 1,
      "dispositivo.bateria_pct": 1,
      "localizacao.nome_local": 1
    }
  )
  .sort({ "dispositivo.bateria_pct": 1, timestamp: -1 })
  .limit(10)
  .toArray()
);

// Consulta 04
print("\n=== Consulta 04 ===");
printjson(
  db.logs_auditoria.find(
    {
      acao: "SELECT",
      tags: { $all: ["dado_sensivel", "lgpd"] }
    },
    {
      _id: 0,
      timestamp: 1,
      "usuario.id_funcionario": 1,
      "usuario.login": 1,
      "usuario.cargo": 1,
      "usuario.setor": 1,
      entidade: 1,
      "contexto_acesso.ip": 1,
      "contexto_acesso.estacao": 1,
      tags: 1
    }
  )
  .sort({ timestamp: -1 })
  .limit(10)
  .toArray()
);

// Consulta 05
print("\n=== Consulta 05 ===");
printjson(
  db.logs_auditoria.find(
    {
      acao: "LOGIN",
      "contexto_acesso.sucesso": false,
      motivo_falha: { $exists: true }
    },
    {
      _id: 0,
      timestamp: 1,
      "usuario.login": 1,
      "usuario.setor": 1,
      "contexto_acesso.ip": 1,
      "contexto_acesso.estacao": 1,
      motivo_falha: 1,
      hash_registro: 1
    }
  )
  .sort({ timestamp: -1 })
  .limit(10)
  .toArray()
);

// Consulta 06
print("\n=== Consulta 06 ===");
printjson(
  db.logs_auditoria.find(
    {
      $and: [
        { acao: "UPDATE" },
        { modulo: { $in: ["ATENDIMENTO", "INTERNACAO"] } },
        { "usuario.setor": { $in: ["Pronto-Socorro", "UTI"] } },
        { alteracoes: { $exists: true } }
      ]
    },
    {
      _id: 0,
      timestamp: 1,
      modulo: 1,
      "usuario.login": 1,
      "usuario.setor": 1,
      entidade: 1,
      alteracoes: 1
    }
  )
  .sort({ timestamp: -1 })
  .limit(10)
  .toArray()
);

// Consulta 07
print("\n=== Consulta 07 ===");
printjson(
  db.intercorrencias_atendimento.find(
    {
      status: { $ne: "RESOLVIDA" },
      data_hora_resolucao: null,
      rascunho: { $ne: true }
    },
    {
      _id: 0,
      codigo_intercorrencia: 1,
      id_atendimento: 1,
      id_local: 1,
      data_hora: 1,
      categoria: 1,
      gravidade: 1,
      status: 1,
      "responsavel.login": 1,
      descricao: 1
    }
  )
  .sort({ data_hora: -1 })
  .limit(15)
  .toArray()
);

// Consulta 08
print("\n=== Consulta 08 ===");
printjson(
  db.intercorrencias_atendimento.find(
    {
      tags: "uti",
      medidas_adotadas: { $size: 4 },
      categoria: { $in: ["RESPIRATORIA", "HEMODINAMICA", "CARDIOVASCULAR"] }
    },
    {
      _id: 0,
      codigo_intercorrencia: 1,
      id_atendimento: 1,
      data_hora: 1,
      categoria: 1,
      gravidade: 1,
      "responsavel.login": 1,
      "medidas_adotadas.ordem": 1,
      "medidas_adotadas.acao": 1
    }
  )
  .sort({ data_hora: -1 })
  .limit(10)
  .toArray()
);

// Consulta 09
print("\n=== Consulta 09 ===");
printjson(
  db.intercorrencias_atendimento.find(
    {
      id_paciente: null,
      id_cadastro_provisorio: { $ne: null },
      $nor: [
        { gravidade: "BAIXA" },
        { gravidade: "MEDIA" }
      ]
    },
    {
      _id: 0,
      codigo_intercorrencia: 1,
      id_atendimento: 1,
      id_cadastro_provisorio: 1,
      data_hora: 1,
      categoria: 1,
      gravidade: 1,
      status: 1,
      descricao: 1,
      tags: 1
    }
  )
  .sort({ data_hora: -1 })
  .limit(10)
  .toArray()
);

// Consulta 10
print("\n=== Consulta 10 ===");
printjson(
  db.linha_tempo_atendimento.find(
    {
      data_hora_encerramento: null,
      "classificacao_risco.prioridade": { $lte: 3 },
      total_eventos: { $gte: 5 }
    },
    {
      _id: 0,
      id_atendimento: 1,
      paciente_ref: 1,
      classificacao_risco: 1,
      status_atual: 1,
      "local_atual.nome": 1,
      data_hora_entrada: 1,
      total_eventos: 1
    }
  )
  .sort({ "classificacao_risco.prioridade": 1, data_hora_entrada: 1 })
  .limit(10)
  .toArray()
);

// Consulta 11
print("\n=== Consulta 11 ===");
printjson(
  db.linha_tempo_atendimento.find(
    {
      eventos: {
        $elemMatch: {
          tipo: "RESULTADO_EXAME",
          "detalhes.situacao": "C"
        }
      },
      "eventos.tipo": "INTERNACAO"
    },
    {
      _id: 0,
      id_atendimento: 1,
      classificacao_risco: 1,
      status_atual: 1,
      queixa_principal: 1,
      data_hora_entrada: 1,
      total_eventos: 1
    }
  )
  .sort({ total_eventos: -1, data_hora_entrada: -1 })
  .limit(10)
  .toArray()
);

// Consulta 12
print("\n=== Consulta 12 ===");
printjson(
  db.linha_tempo_atendimento.find(
    {
      queixa_principal: {
        $regex: "dor no peito|dor tor[áa]cica|falta de ar",
        $options: "i"
      },
      classificacao_risco: { $ne: null },
      "classificacao_risco.cor": { $nin: ["Azul", "Verde"] }
    },
    {
      _id: 0,
      id_atendimento: 1,
      classificacao_risco: 1,
      status_atual: 1,
      queixa_principal: 1,
      data_hora_entrada: 1,
      total_eventos: 1,
      eventos: { $slice: -3 }
    }
  )
  .sort({ "classificacao_risco.prioridade": 1, data_hora_entrada: -1 })
  .limit(10)
  .toArray()
);