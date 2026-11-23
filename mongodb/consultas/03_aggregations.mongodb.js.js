use("gestao_emergencia_hospitalar");

// Pipeline 01
print("\n=== Pipeline 01 ===");
printjson(
  db.telemetria_sinais_vitais.aggregate([
    {
      $match: {
        qualidade_sinal: "OK",
        "sinais.saturacao_o2_pct": { $ne: null }
      }
    },
    {
      $group: {
        _id: {
          tipo_local: "$localizacao.tipo_local",
          nome_local: "$localizacao.nome_local"
        },
        total_leituras: { $sum: 1 },
        fc_media_bpm: { $avg: "$sinais.frequencia_cardiaca_bpm" },
        spo2_media_pct: { $avg: "$sinais.saturacao_o2_pct" },
        spo2_minima_pct: { $min: "$sinais.saturacao_o2_pct" },
        temp_media_c: { $avg: "$sinais.temperatura_c" },
        leituras_com_alerta: {
          $sum: {
            $cond: [
              { $gt: [{ $size: { $ifNull: ["$alertas_disparados", []] } }, 0] },
              1,
              0
            ]
          }
        }
      }
    },
    {
      $project: {
        _id: 0,
        tipo_local: "$_id.tipo_local",
        nome_local: "$_id.nome_local",
        total_leituras: 1,
        leituras_com_alerta: 1,
        taxa_alerta_pct: {
          $round: [
            { $multiply: [{ $divide: ["$leituras_com_alerta", "$total_leituras"] }, 100] },
            2
          ]
        },
        fc_media_bpm: { $round: ["$fc_media_bpm", 1] },
        spo2_media_pct: { $round: ["$spo2_media_pct", 1] },
        spo2_minima_pct: 1,
        temp_media_c: { $round: ["$temp_media_c", 2] }
      }
    },
    {
      $sort: { leituras_com_alerta: -1, spo2_media_pct: 1 }
    },
    {
      $limit: 10
    }
  ]).toArray()
);

// Pipeline 02
print("\n=== Pipeline 02 ===");
printjson(
  db.telemetria_sinais_vitais.aggregate([
    {
      $match: {
        "localizacao.tipo_local": { $in: ["U", "E"] },
        "alertas_disparados.0": { $exists: true }
      }
    },
    {
      $unwind: "$alertas_disparados"
    },
    {
      $match: {
        "alertas_disparados.severidade": { $in: ["ALTA", "CRITICA"] }
      }
    },
    {
      $group: {
        _id: {
          codigo: "$alertas_disparados.codigo",
          severidade: "$alertas_disparados.severidade"
        },
        total_alertas: { $sum: 1 },
        valor_medio_medido: { $avg: "$alertas_disparados.valor_medido" },
        atendimentos_set: { $addToSet: "$id_atendimento" }
      }
    },
    {
      $project: {
        _id: 0,
        codigo_alerta: "$_id.codigo",
        severidade: "$_id.severidade",
        total_alertas: 1,
        atendimentos_afetados: { $size: "$atendimentos_set" },
        valor_medio_medido: { $round: ["$valor_medio_medido", 1] }
      }
    },
    {
      $sort: { total_alertas: -1 }
    }
  ]).toArray()
);

// Pipeline 03
print("\n=== Pipeline 03 ===");
printjson(
  db.linha_tempo_atendimento.aggregate([
    {
      $match: {
        "classificacao_risco.prioridade": { $lte: 2 },
        "eventos.tipo": "INTERCORRENCIA"
      }
    },
    {
      $unwind: "$eventos"
    },
    {
      $match: {
        "eventos.tipo": "INTERCORRENCIA"
      }
    },
    {
      $lookup: {
        from: "intercorrencias_atendimento",
        localField: "eventos.detalhes.codigo_intercorrencia",
        foreignField: "codigo_intercorrencia",
        as: "intercorrencia"
      }
    },
    {
      $unwind: "$intercorrencia"
    },
    {
      $group: {
        _id: {
          cor_risco: "$classificacao_risco.cor",
          categoria: "$intercorrencia.categoria"
        },
        total_ocorrencias: { $sum: 1 },
        casos_criticos: {
          $sum: {
            $cond: [{ $eq: ["$intercorrencia.gravidade", "CRITICA"] }, 1, 0]
          }
        },
        media_medidas: {
          $avg: {
            $size: { $ifNull: ["$intercorrencia.medidas_adotadas", []] }
          }
        }
      }
    },
    {
      $project: {
        _id: 0,
        cor_risco: "$_id.cor_risco",
        categoria: "$_id.categoria",
        total_ocorrencias: 1,
        casos_criticos: 1,
        media_medidas_adotadas: { $round: ["$media_medidas", 2] }
      }
    },
    {
      $sort: { total_ocorrencias: -1, casos_criticos: -1 }
    },
    {
      $limit: 15
    }
  ]).toArray()
);

// Pipeline 04
print("\n=== Pipeline 04 ===");
printjson(
  db.logs_auditoria.aggregate([
    {
      $match: {
        timestamp: { $gte: ISODate("2026-04-01T00:00:00Z") }
      }
    },
    {
      $group: {
        _id: "$usuario.setor",
        total_acoes: { $sum: 1 },
        usuarios_unicos: { $addToSet: "$usuario.id_funcionario" },
        acessos_lgpd: {
          $sum: {
            $cond: [
              { $in: ["lgpd", { $ifNull: ["$tags", []] }] },
              1,
              0
            ]
          }
        },
        falhas_login: {
          $sum: {
            $cond: [{ $eq: ["$contexto_acesso.sucesso", false] }, 1, 0]
          }
        }
      }
    },
    {
      $project: {
        _id: 0,
        setor: "$_id",
        total_acoes: 1,
        usuarios_ativos: { $size: "$usuarios_unicos" },
        acessos_lgpd: 1,
        falhas_login: 1
      }
    },
    {
      $sort: { total_acoes: -1 }
    }
  ]).toArray()
);