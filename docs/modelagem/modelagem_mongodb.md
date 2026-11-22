# Modelagem MongoDB

**Projeto:** Sistema de Gestão de Emergências e Atendimento Hospitalar
**Banco:** `gestao_emergencia_hospitalar` (MongoDB)
**Volume carregado:** 106.336 documentos em 4 collections

## 1. Por que MongoDB neste projeto

O MySQL continua sendo a fonte oficial do hospital: cadastros, atendimentos, prescrições, estoque e internações, tudo com chave estrangeira e regras de integridade. O MongoDB entra onde o modelo relacional fica caro ou engessado:

- **Telemetria dos monitores (RF43):** chegam milhares de leituras por dia, cada uma com uma quantidade variável de alertas. Gravar isso em tabela significaria uma linha por leitura mais uma tabela de alertas, e o MySQL ficaria ocupado com inserções enquanto atende a recepção.
- **Auditoria imutável (RF31–RF33):** cada ação tem um formato diferente (um LOGIN não tem "antes e depois"; um UPDATE tem). Documento flexível resolve sem colunas vazias. Os registros são apenas inseridos (*append-only*) e encadeados por hash.
- **Intercorrências (RF22):** cada evento tem uma lista de medidas adotadas que varia de tamanho; o documento guarda tudo junto.
- **Linha do tempo (RF23):** montar o prontuário de um atendimento no MySQL exige juntar atendimento, triagem, sinais vitais, solicitações, resultados, internação, transferências e alta. No MongoDB isso já fica pronto em um único documento.

Nenhuma collection é cópia de tabela: elas guardam o que não cabe bem no relacional ou o que precisa ser lido rápido, sempre apontando para os IDs reais do MySQL.

## 2. Ligação com o MySQL e regras dos dados

- **Referências por ID:** `id_atendimento`, `id_paciente`, `id_cadastro_provisorio`, `id_funcionario`, `id_equipamento`, `id_local`, `id_leito`, `id_solicitacao` etc. são os mesmos IDs dos INSERTs do MySQL (`mysql/dml/01` a `37`). O MongoDB não tem chave estrangeira; quem garante a ligação é o script gerador, que lê os próprios arquivos `.sql`.
- **Sem CPF, senha ou registro profissional (LGPD):** o vínculo com pessoas é sempre por ID. Como complemento legível entram só chaves não sensíveis: `login` e cargo do funcionário, `numero_patrimonio` do equipamento.
- **Paciente sem identificação:** quando o atendimento é de um cadastro provisório, `id_paciente` é `null` e `id_cadastro_provisorio` vem preenchido (igual à tabela `atendimento`).
- **Datas em UTC:** o MySQL guarda horário de Brasília; no MongoDB tudo é `Date` em UTC (+3 h). Nos arquivos de carga as datas aparecem no formato Extended JSON `{"$date": "2026-04-02T01:05:52Z"}`, que o MongoDB Compass (Add Data > Import JSON) e o `mongosh` convertem automaticamente para `Date`.
- **Coerência temporal:** toda leitura, intercorrência e evento acontece entre a entrada do paciente e a alta (ou o momento da carga, se o atendimento ainda está aberto).

## 3. Embutir ou referenciar

| Dado | Decisão | Motivo |
|---|---|---|
| Sinais medidos, dados do dispositivo, local e leito na telemetria | **Embutido** | A leitura é lida sempre inteira e nunca muda depois de gravada |
| Alertas de cada leitura | **Array embutido** | Quantidade variável (0 a 5) e só fazem sentido junto da leitura |
| Usuário que fez a ação na auditoria | **Embutido** (cópia de id, login, cargo, setor) | O log é imutável: precisa registrar o cargo da pessoa naquele momento, mesmo que ela mude de cargo depois |
| Medidas adotadas na intercorrência | **Array embutido** | Pertencem só àquela intercorrência e são lidas junto |
| Eventos do atendimento | **Array embutido** na linha do tempo | É exatamente o prontuário que a tela precisa abrir de uma vez |
| Paciente, funcionário, equipamento, leito, exames | **Referência** ao MySQL por ID | Dado mestre fica num lugar só; o MongoDB não duplica cadastro |
| Intercorrência dentro da linha do tempo | **Referência** por `codigo_intercorrencia` | Evita duplicar o detalhe; o `$lookup` junta quando precisar |

## 4. Collections

### 4.1 `telemetria_sinais_vitais` — 75.013 documentos

Leituras dos monitores multiparamétricos e oxímetros de pacientes na sala vermelha, sala amarela, observação, enfermarias e UTIs. Na UTI o envio é mais frequente que na enfermaria. Cada aparelho atende um paciente por vez, e os valores partem das aferições reais da tabela `sinais_vitais`, com variação natural e picos coerentes com as intercorrências registradas.

| Campo | Tipo | Observação |
|---|---|---|
| `id_atendimento` | int | `atendimento.id_atendimento` |
| `paciente_ref` | objeto | `id_paciente` (int ou null), `id_cadastro_provisorio` (int ou null), `identificado` (bool) |
| `dispositivo` | objeto | `id_equipamento`, `numero_patrimonio`, `modelo`, `bateria_pct` |
| `localizacao` | objeto | `id_local`, `nome_local`, `tipo_local`, `id_leito` e `numero_leito` (null fora de leito) |
| `timestamp` | date | Momento da leitura (UTC) |
| `sinais` | objeto | FC, FR, pressão (objeto ou null em bebês), SpO2 (null quando o sensor perde o sinal) e temperatura (decimal) |
| `alertas_disparados` | array | `codigo`, `severidade` (BAIXA, MEDIA, ALTA, CRITICA), `valor_medido`, `limite_referencia`; vazio em leitura normal |
| `qualidade_sinal` | string | `OK`, `INTERFERENCIA` ou `SEM_SINAL_SPO2` |

Limites usados nos alertas: SpO2 < 92%, FC > 100 bpm (crianças têm limite maior), FC < 50, PA sistólica < 90 ou > 180 mmHg, FR > 24 irpm e temperatura ≥ 37,8 °C.

```json
{
  "id_atendimento": 2,
  "paciente_ref": {
    "id_paciente": 853,
    "id_cadastro_provisorio": null,
    "identificado": true
  },
  "dispositivo": {
    "id_equipamento": 141,
    "numero_patrimonio": "PAT-2023-00141",
    "modelo": "Monitor multiparamétrico MP-12",
    "bateria_pct": 93
  },
  "localizacao": {
    "id_local": 35,
    "nome_local": "Enfermaria 203",
    "tipo_local": "I",
    "id_leito": 24,
    "numero_leito": "203-A"
  },
  "timestamp": {
    "$date": "2026-04-02T01:05:52Z"
  },
  "sinais": {
    "frequencia_cardiaca_bpm": 114,
    "frequencia_respiratoria_irpm": 25,
    "pressao_arterial": {
      "sistolica_mmhg": 143,
      "diastolica_mmhg": 75
    },
    "saturacao_o2_pct": 93,
    "temperatura_c": 36.8
  },
  "alertas_disparados": [
    {
      "codigo": "TAQUICARDIA",
      "severidade": "BAIXA",
      "valor_medido": 114,
      "limite_referencia": 100
    },
    {
      "codigo": "TAQUIPNEIA",
      "severidade": "MEDIA",
      "valor_medido": 25,
      "limite_referencia": 24
    }
  ],
  "qualidade_sinal": "OK"
}
```

### 4.2 `logs_auditoria` — 27.704 documentos

Trilha imutável das ações dos usuários: login e logout (a partir do registro de ponto), abertura de atendimento, triagem, mudanças de status, consulta ao prontuário, solicitações de exame e procedimento, laudos, internação, ocupação de leito, transferências e altas. Cada documento guarda o hash do anterior (`hash_anterior`) e o próprio (`hash_registro`, SHA-256): se alguém alterar um registro antigo, a corrente quebra.

| Campo | Tipo | Observação |
|---|---|---|
| `timestamp` | date | Momento da ação (UTC) |
| `usuario` | objeto | `id_funcionario`, `login`, `cargo`, `setor` |
| `acao` | string | `INSERT`, `UPDATE`, `SELECT`, `LOGIN`, `LOGOUT` |
| `modulo` | string | `ATENDIMENTO`, `TRIAGEM`, `PRONTUARIO`, `SOLICITACOES`, `EXAMES`, `INTERNACAO`, `LEITOS`, `ALTA`, `AUTENTICACAO` |
| `entidade` | objeto | `tabela` (nome real no MySQL) e `registro_id` |
| `alteracoes` | objeto ou ausente | `antes` (null em INSERT) e `depois`; não existe em SELECT, LOGIN e LOGOUT |
| `contexto_acesso` | objeto | `ip`, `estacao`, `sucesso` (false nas tentativas de login que falharam) |
| `motivo_falha` | string (opcional) | Só nas falhas de login |
| `tags` | array de string | Classificação livre (ex.: `dado_sensivel`, `lgpd`) |
| `hash_anterior`, `hash_registro` | string | Encadeamento de integridade |

Exemplo de UPDATE (com `alteracoes`):

```json
{
  "timestamp": {
    "$date": "2026-04-01T09:44:53Z"
  },
  "usuario": {
    "id_funcionario": 164,
    "login": "viviane.castro",
    "cargo": "Enfermeiro",
    "setor": "Enfermagem"
  },
  "acao": "UPDATE",
  "modulo": "ATENDIMENTO",
  "entidade": {
    "tabela": "atendimento",
    "registro_id": 1
  },
  "alteracoes": {
    "antes": {
      "id_status": 1
    },
    "depois": {
      "id_status": 2
    }
  },
  "contexto_acesso": {
    "ip": "10.20.3.174",
    "estacao": "ENF-TERM-15",
    "sucesso": true
  },
  "tags": [
    "mudanca_status"
  ],
  "hash_anterior": "e0c6498d8e5c4c4c7be67b20a1847973b4024117facdac4a2b1199f2f5fe8c99",
  "hash_registro": "af64934911127eca8f79ab8dec5931081ce4550a531f277f756a92cc0e87c38a"
}
```

Exemplo de SELECT de dado sensível (sem `alteracoes`, mostrando o schema flexível):

```json
{
  "timestamp": {
    "$date": "2026-04-01T09:52:54Z"
  },
  "usuario": {
    "id_funcionario": 153,
    "login": "maria.silva",
    "cargo": "Médico plantonista clínico",
    "setor": "Pronto-Socorro"
  },
  "acao": "SELECT",
  "modulo": "PRONTUARIO",
  "entidade": {
    "tabela": "historico_clinico",
    "registro_id": 852
  },
  "contexto_acesso": {
    "ip": "10.20.2.163",
    "estacao": "PS-TERM-04",
    "sucesso": true
  },
  "tags": [
    "dado_sensivel",
    "lgpd",
    "prontuario"
  ],
  "hash_anterior": "af64934911127eca8f79ab8dec5931081ce4550a531f277f756a92cc0e87c38a",
  "hash_registro": "33f6b88d7ee06b9550be55ebd1cff8baf3a275b62e186eb2aa4454b83a30e99d"
}
```

### 4.3 `intercorrencias_atendimento` — 1.419 documentos

Eventos adversos durante o atendimento: queda de saturação, hipotensão, taquicardia, convulsão, queda do leito, perda de acesso venoso, reação a medicamento, febre etc. A categoria segue o quadro do paciente (o CID da alta), a gravidade é coerente com a cor da triagem e o responsável é um médico ou enfermeiro que de fato atuou naquele atendimento. Diferente da auditoria, esta collection muda de estado: `ABERTA` → `EM_ACOMPANHAMENTO` → `RESOLVIDA`. Os casos ainda em aberto pertencem a pacientes internados no momento da carga.

| Campo | Tipo | Observação |
|---|---|---|
| `codigo_intercorrencia` | string | Único, `INT-AAAA-NNNNNN`; usado no `$lookup` com a linha do tempo |
| `id_atendimento`, `id_paciente`, `id_cadastro_provisorio`, `id_local` | int / null | Iguais ao MySQL |
| `data_hora` | date | Início do evento |
| `categoria` | string | 12 categorias clínicas |
| `gravidade` | string | `BAIXA`, `MEDIA`, `ALTA`, `CRITICA` |
| `status` | string | `ABERTA`, `EM_ACOMPANHAMENTO`, `RESOLVIDA` |
| `descricao` | string | Texto clínico com os valores medidos |
| `responsavel` | objeto | `id_funcionario`, `login`, `cargo` |
| `medidas_adotadas` | array | `ordem`, `acao`, `hora`, `executado_por_id_funcionario` |
| `data_hora_resolucao` | date ou null | Preenchida quando resolvida |
| `tags` | array de string | Ex.: `uti`, `paciente_nao_identificado` |

```json
{
  "codigo_intercorrencia": "INT-2026-000025",
  "id_atendimento": 61,
  "id_paciente": 622,
  "id_cadastro_provisorio": null,
  "id_local": 36,
  "data_hora": {
    "$date": "2026-04-07T13:41:51Z"
  },
  "categoria": "RESPIRATORIA",
  "gravidade": "CRITICA",
  "status": "RESOLVIDA",
  "descricao": "Dispneia intensa com uso de musculatura acessória e saturação de 82%.",
  "responsavel": {
    "id_funcionario": 284,
    "login": "nicolas.cunha",
    "cargo": "Médico hospitalista"
  },
  "medidas_adotadas": [
    {
      "ordem": 1,
      "acao": "Oferta de oxigênio por máscara não reinalante a 10 L/min",
      "hora": {
        "$date": "2026-04-07T13:43:13Z"
      },
      "executado_por_id_funcionario": 38
    },
    {
      "ordem": 2,
      "acao": "Elevação da cabeceira a 45 graus",
      "hora": {
        "$date": "2026-04-07T13:45:29Z"
      },
      "executado_por_id_funcionario": 38
    },
    {
      "ordem": 3,
      "acao": "Solicitação de gasometria arterial de urgência",
      "hora": {
        "$date": "2026-04-07T13:48:36Z"
      },
      "executado_por_id_funcionario": 284
    }
  ],
  "data_hora_resolucao": {
    "$date": "2026-04-07T14:39:36Z"
  },
  "tags": [
    "hipoxemia",
    "oxigenoterapia"
  ]
}
```

### 4.4 `linha_tempo_atendimento` — 2.200 documentos (1 por atendimento)

O prontuário do atendimento em ordem cronológica, montado com os registros reais do MySQL: entrada, triagem, sinais vitais, exames, procedimentos, medicações, laudos, internação, leitos, transferências e alta. Inclui também as intercorrências, por código. Em média são 14 eventos por atendimento.

| Campo | Tipo | Observação |
|---|---|---|
| `id_atendimento` | int | Único (relação 1:1 com a tabela `atendimento`) |
| `paciente_ref` | objeto | `id_paciente`, `id_cadastro_provisorio` |
| `classificacao_risco` | objeto ou null | `cor` e `prioridade` (null se ainda não houve triagem) |
| `status_atual`, `queixa_principal` | string | Do MySQL |
| `local_atual` | objeto | `id_local` e `nome` |
| `data_hora_entrada` | date | Chegada |
| `data_hora_encerramento` | date ou null | Alta; null se o atendimento está aberto |
| `total_eventos` | int | Tamanho do array |
| `eventos` | array | `tipo`, `data_hora`, `id_funcionario`, `resumo` e `detalhes` (formato muda conforme o tipo) |

```json
{
  "id_atendimento": 31,
  "paciente_ref": {
    "id_paciente": 179,
    "id_cadastro_provisorio": null
  },
  "classificacao_risco": {
    "cor": "Amarelo",
    "prioridade": 3
  },
  "status_atual": "Finalizado",
  "queixa_principal": "Dor de cabeça forte desde a manhã",
  "local_atual": {
    "id_local": 15,
    "nome": "Consultório 9"
  },
  "data_hora_entrada": {
    "$date": "2026-04-04T06:28:16Z"
  },
  "data_hora_encerramento": {
    "$date": "2026-04-04T09:17:01Z"
  },
  "total_eventos": 8,
  "eventos": [
    {
      "tipo": "ENTRADA",
      "data_hora": {
        "$date": "2026-04-04T06:28:16Z"
      },
      "id_funcionario": 94,
      "resumo": "Abertura de atendimento (Espontânea) - Queixa: Dor de cabeça forte desde a manhã",
      "detalhes": {
        "tipo_entrada": "E",
        "id_local": 15
      }
    },
    {
      "tipo": "TRIAGEM",
      "data_hora": {
        "$date": "2026-04-04T06:48:01Z"
      },
      "id_funcionario": 35,
      "resumo": "Classificação Amarelo (Urgente)",
      "detalhes": {
        "id_triagem": 31,
        "cor": "Amarelo"
      }
    },
    {
      "tipo": "SINAIS_VITAIS",
      "data_hora": {
        "$date": "2026-04-04T06:48:01Z"
      },
      "id_funcionario": 35,
      "resumo": "PA 144x76, FC 104, SpO2 97%",
      "detalhes": {
        "id_sinais_vitais": 71
      }
    },
    {
      "tipo": "INTERCORRENCIA",
      "data_hora": {
        "$date": "2026-04-04T08:08:25Z"
      },
      "id_funcionario": 3,
      "resumo": "Intercorrência queda (media)",
      "detalhes": {
        "codigo_intercorrencia": "INT-2026-000014",
        "gravidade": "MEDIA"
      }
    },
    {
      "tipo": "MEDICACAO_MATERIAL",
      "data_hora": {
        "$date": "2026-04-04T08:13:01Z"
      },
      "id_funcionario": 11,
      "resumo": "Dipirona 500 mg/mL solução injetável 2 mL (quantidade 1)",
      "detalhes": {
        "id_solicitacao": 186,
        "status": "R",
        "prioridade": "N"
      }
    },
    {
      "tipo": "MEDICACAO_MATERIAL",
      "data_hora": {
        "$date": "2026-04-04T08:14:01Z"
      },
      "id_funcionario": 11,
      "resumo": "Metoclopramida 10 mg/2 mL injetável (quantidade 1)",
      "detalhes": {
        "id_solicitacao": 187,
        "status": "R",
        "prioridade": "N"
      }
    },
    {
      "tipo": "SINAIS_VITAIS",
      "data_hora": {
        "$date": "2026-04-04T09:10:01Z"
      },
      "id_funcionario": 3,
      "resumo": "PA 147x82, FC 92, SpO2 96%",
      "detalhes": {
        "id_sinais_vitais": 77
      }
    },
    {
      "tipo": "ALTA",
      "data_hora": {
        "$date": "2026-04-04T09:17:01Z"
      },
      "id_funcionario": 11,
      "resumo": "Alta médica - CID G44.2",
      "detalhes": {
        "id_alta": 25,
        "tipo_alta": "M",
        "cid_final": "G44.2"
      }
    }
  ]
}
```

## 5. Como os dados atendem às próximas etapas

- **3.4 Consultas:** há alertas das quatro severidades, intercorrências nos três status, leituras com e sem alerta, pacientes identificados e não identificados, e cinco tipos de ação em nove módulos de auditoria.
- **3.5 Update/Delete:** 19 intercorrências estão em `ABERTA` ou `EM_ACOMPANHAMENTO` para serem atualizadas com `$set`. Há também 2 registros de teste (tag `teste_exclusao`, campo `rascunho: true`) para `deleteOne`/`deleteMany`, sem tocar na auditoria.
- **3.6 Aggregation:** dá para agrupar a telemetria por local, tipo de local e aparelho, e para usar `$unwind` em `alertas_disparados`, `medidas_adotadas` e `eventos`. O `$lookup` liga `eventos.detalhes.codigo_intercorrencia` a `intercorrencias_atendimento`.
- **3.7 Índices:** o volume de telemetria e auditoria deixa clara a diferença no `explain("executionStats")`. Bons candidatos: `{ id_atendimento: 1, timestamp: 1 }` na telemetria, `{ "usuario.id_funcionario": 1, timestamp: -1 }` na auditoria e `{ "alertas_disparados.severidade": 1 }`.

## 6. Arquivos

| Arquivo | Para que serve |
|---|---|
| `mongodb/dados/gerar_datasets_mongodb.py` | Lê `mysql/dml/*.sql` e gera os 4 arquivos de carga em `mongodb/datasets/` e as amostras |
| `mongodb/dados/amostras/*.json` | 30 documentos de cada collection (versionados) |
| `mongodb/dados/01_insercao_manual.mongodb.js` | `insertOne` e `insertMany` em todas as collections |

**Ordem de carga:** (1) rodar `gerar_datasets_mongodb.py`; (2) importar os 4 JSONs de `mongodb/datasets/` pelo MongoDB Compass (Add Data > Import JSON); (3) executar `01_insercao_manual.mongodb.js` para inserir os exemplos manuais e os registros de teste de exclusão.
