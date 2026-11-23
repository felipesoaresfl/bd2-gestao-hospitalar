use("gestao_emergencia_hospitalar");

// Operação 01
print("\n=== Operação 01 ===");
printjson(
  db.intercorrencias_atendimento.updateOne(
    {
      status: "ABERTA",
      rascunho: { $ne: true }
    },
    {
      $set: {
        status: "EM_ACOMPANHAMENTO",
        observacao_evolucao: "Equipe clínica assumiu o monitoramento contínuo do paciente.",
        data_ultima_atualizacao: new Date()
      }
    }
  )
);

// Operação 02
print("\n=== Operação 02 ===");
printjson(
  db.intercorrencias_atendimento.updateOne(
    {
      status: "EM_ACOMPANHAMENTO",
      gravidade: "BAIXA",
      rascunho: { $ne: true }
    },
    {
      $set: {
        status: "RESOLVIDA",
        data_hora_resolucao: new Date()
      },
      $addToSet: {
        tags: "encerramento_validado"
      }
    }
  )
);

// Operação 03
print("\n=== Operação 03 ===");
printjson(
  db.intercorrencias_atendimento.updateMany(
    {
      status: "EM_ACOMPANHAMENTO",
      rascunho: { $ne: true }
    },
    {
      $set: {
        revisado_passagem_plantao: true,
        data_revisao_plantao: new Date()
      },
      $addToSet: {
        tags: "revisado_plantao"
      }
    }
  )
);

// Operação 04
print("\n=== Operação 04 ===");
printjson(
  db.intercorrencias_atendimento.deleteOne(
    {
      rascunho: true,
      tags: "teste_exclusao"
    }
  )
);

// Operação 05
print("\n=== Operação 05 ===");
printjson(
  db.intercorrencias_atendimento.deleteMany(
    {
      rascunho: true,
      tags: "teste_exclusao"
    }
  )
);