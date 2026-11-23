# Consultas, Manipulação de Dados e Aggregations no MongoDB (Itens 3.4, 3.5 e 3.6)

**Banco:** `gestao_emergencia_hospitalar` · **SGBD:** MongoDB · **Collections:** 4 (`telemetria_sinais_vitais`, `logs_auditoria`, `intercorrencias_atendimento`, `linha_tempo_atendimento`)

---

## 1. Visão geral dos scripts e ordem de execução

Os scripts operacionais e analíticos ficam organizados na pasta `mongodb/consultas/`:

| Arquivo | Item | Escopo | Efeito no banco |
|---|---|---|---|
| `01_consultas.mongodb.js` | 3.4 | 12 consultas de leitura (`find`, projeções, ordenação e limites) | Somente leitura |
| `03_aggregations.mongodb.js` | 3.6 | 4 pipelines analíticos (`aggregate`, incluindo `$unwind` e `$lookup`) | Somente leitura |
| `02_atualizacao_exclusao.mongodb.js` | 3.5 | 5 operações de escrita (`updateOne`, `updateMany`, `deleteOne`, `deleteMany`) | Altera status e remove rascunhos de teste |

### Ordem recomendada para execução e testes

1. Garantir que a carga dos datasets e o script `mongodb/dados/01_insercao_manual.mongodb.js` já foram executados (ele insere os 2 documentos de rascunho marcados com `rascunho: true` e tag `"teste_exclusao"`).
2. Executar `01_consultas.mongodb.js` e `03_aggregations.mongodb.js` primeiro, preservando o estado original da base para leitura.
3. Executar `02_atualizacao_exclusao.mongodb.js` por último, validando as alterações de fluxo clínico e a limpeza dos rascunhos de teste.

---

## 2. Consultas de Leitura (`01_consultas.mongodb.js` — Item 3.4)

As 12 consultas cobrem as 4 collections (3 consultas por collection) e exercitam operadores de comparação (`$lt`, `$gt`, `$lte`, `$gte`, `$ne`), pertinência (`$in`, `$nin`), lógicos (`$or`, `$and`, `$nor`), avaliação de elementos e arrays (`$elemMatch`, `$all`, `$size`, `$exists`), expressão regular (`$regex`), fatiamento de array em projeção (`$slice`), ordenação (`.sort()`) e paginação (`.limit()`).

### 2.1 `telemetria_sinais_vitais`

| # | Pergunta clínica / operacional respondida | Filtros e operadores aplicados | Ordenação e limite |
|---|---|---|---|
| **01** | Quais são as 10 leituras mais graves em leitos de UTI que combinam hipoxemia (saturação abaixo de 90%) e taquicardia (frequência cardíaca acima de 110 bpm)? | `localizacao.tipo_local: "U"`, `sinais.saturacao_o2_pct` (`$lt: 90`), `sinais.frequencia_cardiaca_bpm` (`$gt: 110`) | Menor SpO2 primeiro e leitura mais recente (`saturacao_o2_pct: 1, timestamp: -1`), limite 10 |
| **02** | Quais foram os 10 alertas de severidade crítica mais recentes de hipoxemia ou hipotensão registrados entre outubro e novembro de 2026? | Intervalo em `timestamp` (`$gte` e `$lte`) + `$elemMatch` em `alertas_disparados` exigindo `severidade: "CRITICA"` e `codigo` em `$in: ["HIPOXEMIA", "HIPOTENSAO"]` no mesmo alerta | Mais recentes primeiro (`timestamp: -1`), limite 10 |
| **03** | Quais pacientes ainda não identificados estão em risco de perda de monitoramento por sinal degradado ou bateria do monitor em nível baixo (75% ou menos)? | `paciente_ref.identificado: false` combinado com `$or` entre `qualidade_sinal` (`$ne: "OK"`) e `dispositivo.bateria_pct` (`$lte: 75`) | Menor nível de bateria primeiro e mais recente (`bateria_pct: 1, timestamp: -1`), limite 10 |

### 2.2 `logs_auditoria`

| # | Pergunta de segurança / conformidade respondida | Filtros e operadores aplicados | Ordenação e limite |
|---|---|---|---|
| **04** | Quais foram os 10 acessos de leitura (`SELECT`) mais recentes a registros classificados simultaneamente como dado sensível e sujeitos à LGPD? | `acao: "SELECT"` e `tags` com `$all: ["dado_sensivel", "lgpd"]` | Mais recentes primeiro (`timestamp: -1`), limite 10 |
| **05** | Quais foram as 10 tentativas mais recentes de login malsucedidas que possuem motivo de falha registrado para investigação de segurança? | `acao: "LOGIN"`, `contexto_acesso.sucesso: false` e `motivo_falha` (`$exists: true`) | Mais recentes primeiro (`timestamp: -1`), limite 10 |
| **06** | Quais foram as 10 modificações (`UPDATE`) mais recentes com registro de alterações nos módulos de Atendimento ou Internação feitas por equipes do Pronto-Socorro ou da UTI? | `$and` combinando `acao: "UPDATE"`, `modulo` (`$in: ["ATENDIMENTO", "INTERNACAO"]`), `usuario.setor` (`$in: ["Pronto-Socorro", "UTI"]`) e `alteracoes` (`$exists: true`) | Mais recentes primeiro (`timestamp: -1`), limite 10 |

### 2.3 `intercorrencias_atendimento`

| # | Pergunta clínica / operacional respondida | Filtros e operadores aplicados | Ordenação e limite |
|---|---|---|---|
| **07** | Quais são as 15 intercorrências clínicas mais recentes que continuam pendentes de resolução no plantão (descartando rascunhos)? | `status` (`$ne: "RESOLVIDA"`), `data_hora_resolucao: null` e `rascunho` (`$ne: true`) | Mais recentes primeiro (`data_hora: -1`), limite 15 |
| **08** | Quais intercorrências mais recentes na UTI das categorias respiratória, hemodinâmica ou cardiovascular exigiram exatamente 4 medidas clínicas registradas? | `tags: "uti"`, `medidas_adotadas` (`$size: 4`) e `categoria` (`$in: ["RESPIRATORIA", "HEMODINAMICA", "CARDIOVASCULAR"]`) | Mais recentes primeiro (`data_hora: -1`), limite 10 |
| **09** | Quais são as 10 intercorrências de gravidade alta ou crítica mais recentes envolvendo pacientes sem identificação definitiva (atendidos com cadastro provisório)? | `id_paciente: null`, `id_cadastro_provisorio` (`$ne: null`) e `$nor` excluindo gravidades `"BAIXA"` e `"MEDIA"` | Mais recentes primeiro (`data_hora: -1`), limite 10 |

### 2.4 `linha_tempo_atendimento`

| # | Pergunta clínica / operacional respondida | Filtros e operadores aplicados | Ordenação e limite |
|---|---|---|---|
| **10** | Quais são os 10 atendimentos ainda abertos de maior prioridade de risco (Vermelho, Laranja ou Amarelo) e alta movimentação clínica (5 ou mais eventos)? | `data_hora_encerramento: null`, `classificacao_risco.prioridade` (`$lte: 3`) e `total_eventos` (`$gte: 5`) | Maior prioridade e maior tempo de espera (`prioridade: 1, data_hora_entrada: 1`), limite 10 |
| **11** | Quais atendimentos apresentaram resultado de exame crítico e também evoluíram para internação hospitalar? | `$elemMatch` em `eventos` (`tipo: "RESULTADO_EXAME"` e `detalhes.situacao: "C"`) combinado com `"eventos.tipo": "INTERNACAO"` | Maior quantidade de eventos e entrada mais recente (`total_eventos: -1, data_hora_entrada: -1`), limite 10 |
| **12** | Quais são os 10 atendimentos urgentes (excluindo classificações Azul e Verde) cuja queixa principal menciona sinais cardiorrespiratórios ("dor no peito", "dor torácica" ou "falta de ar"), exibindo os últimos 3 eventos registrados? | `queixa_principal` com `$regex` case-insensitive (`$options: "i"`), `classificacao_risco` (`$ne: null`), `classificacao_risco.cor` (`$nin: ["Azul", "Verde"]`) e projeção com `eventos: { $slice: -3 }` | Maior prioridade e entrada mais recente (`prioridade: 1, data_hora_entrada: -1`), limite 10 |

---

## 3. Atualização e Exclusão (`02_atualizacao_exclusao.mongodb.js` — Item 3.5)

### Política de integridade e governança aplicada

* **Collections imutáveis preservadas:** nenhuma operação de atualização ou exclusão atua sobre `logs_auditoria` (trilha *append-only* exigida por auditoria e LGPD) nem sobre `telemetria_sinais_vitais` (série histórica de leituras clínicas).
* **Exclusões seguras:** os comandos `deleteOne` e `deleteMany` removem exclusivamente documentos de rascunho marcados com `rascunho: true` e tag `"teste_exclusao"`, evitando perda de histórico assistencial real.

### Operações executadas e resultados validados

| Operação | Comando | Collection | O que faz na prática | Operadores de escrita | Resultado validado |
|---|---|---|---|---|---|
| **01** | `updateOne` | `intercorrencias_atendimento` | Assume o monitoramento de 1 intercorrência real com status `ABERTA`, alterando para `EM_ACOMPANHAMENTO` e registrando evolução e carimbo de data/hora. | `$set` | `matchedCount: 1`, `modifiedCount: 1` |
| **02** | `updateOne` | `intercorrencias_atendimento` | Encerra 1 intercorrência real `EM_ACOMPANHAMENTO` de gravidade `BAIXA`, alterando para `RESOLVIDA`, preenchendo `data_hora_resolucao` e adicionando a tag `"encerramento_validado"` sem duplicar. | `$set`, `$addToSet` | `matchedCount: 1`, `modifiedCount: 1` |
| **03** | `updateMany` | `intercorrencias_atendimento` | Marca em lote todas as intercorrências reais ainda `EM_ACOMPANHAMENTO` como revisadas na passagem de plantão, registrando `revisado_passagem_plantao: true`, `data_revisao_plantao` e a tag `"revisado_plantao"`. | `$set`, `$addToSet` | `matchedCount: 12`, `modifiedCount: 12` |
| **04** | `deleteOne` | `intercorrencias_atendimento` | Remove o primeiro rascunho de teste (`rascunho: true`, `tags: "teste_exclusao"`). | — | `deletedCount: 1` |
| **05** | `deleteMany` | `intercorrencias_atendimento` | Remove os rascunhos de teste restantes (`rascunho: true`, `tags: "teste_exclusao"`), concluindo a limpeza sem afetar dados clínicos. | — | `deletedCount: 1` |

---

## 4. Aggregation Pipelines (`03_aggregations.mongodb.js` — Item 3.6)

Os 4 pipelines cobrem todas as collections do banco e empregam estágios de filtragem (`$match`), desmembramento de arrays (`$unwind`), junção entre collections (`$lookup`), agrupamento com métricas condicionais (`$group`, `$sum`, `$avg`, `$min`, `$cond`, `$addToSet`), projeção com cálculos arredondados (`$project`, `$round`, `$divide`, `$multiply`, `$size`, `$ifNull`), ordenação (`$sort`) e limite (`$limit`).

### Pipeline 01 — Panorama clínico e taxa de alertas por setor (`telemetria_sinais_vitais`)

* **Pergunta respondida:** Quais setores/locais do hospital concentram mais leituras com alerta e quais são as médias de frequência cardíaca, temperatura e saturação de oxigênio (incluindo a mínima registrada) em cada local?
* **Estágios utilizados:** `$match` -> `$group` -> `$project` -> `$sort` -> `$limit` (top 10).
* **Lógica aplicada:** filtra leituras com `qualidade_sinal: "OK"` e `saturacao_o2_pct` preenchido, agrupa por `tipo_local` e `nome_local`, calcula o percentual de leituras com alertas (`taxa_alerta_pct`) e ordena pelos setores com maior volume de alertas e menor saturação média.
* **Validação:** retornou os 10 setores com métricas coerentes com o perfil clínico (por exemplo, *Observação pediátrica* apresentou 2.110 leituras, taxa de alerta de 32,09%, SpO2 mínima de 82% e frequência cardíaca média de 113,3 bpm, compatível com faixa pediátrica).

### Pipeline 02 — Ranking de alertas críticos e altos em áreas críticas (`telemetria_sinais_vitais`)

* **Pergunta respondida:** Quais tipos de alertas de severidade `ALTA` ou `CRITICA` mais disparam na UTI (`"U"`) e na Emergência (`"E"`), quantos atendimentos distintos cada alerta afeta e qual o valor médio medido?
* **Estágios utilizados:** `$match` -> `$unwind` (`$alertas_disparados`) -> `$match` -> `$group` -> `$project` -> `$sort`.
* **Lógica aplicada:** restringe antes do `$unwind` para reduzir memória, desmembra cada alerta do array `alertas_disparados`, mantém severidades `ALTA` e `CRITICA` e utiliza `$addToSet` sobre `id_atendimento` para contabilizar atendimentos únicos afetados.
* **Validação:** retornou os 10 grupos de alertas ordenados por volume, liderados por `HIPERTENSAO` (`ALTA`, 309 alertas, 55 atendimentos, média 209,3), `TAQUICARDIA` (`ALTA`, 294 alertas, 70 atendimentos, média 136,2) e `TAQUIPNEIA` (`ALTA`, 269 alertas, 91 atendimentos, média 32,1), além dos alertas `CRITICA` como `HIPOTENSAO` (119 alertas, média 69,6), `TAQUICARDIA` (64 alertas, média 160,3) e `HIPOXEMIA` (62 alertas, média 82,9%).

### Pipeline 03 — Cruzamento entre risco na triagem e perfil de intercorrências (`linha_tempo_atendimento` + `intercorrencias_atendimento`)

* **Pergunta respondida:** Nos atendimentos de risco mais elevado (prioridades 1 e 2 — Vermelho e Laranja), quais categorias de intercorrências mais ocorrem, quantas atingem gravidade crítica e qual a média de medidas clínicas adotadas?
* **Estágios utilizados:** `$match` -> `$unwind` (`$eventos`) -> `$match` -> `$lookup` -> `$unwind` (`$intercorrencia`) -> `$group` -> `$project` -> `$sort` -> `$limit` (top 15).
* **Lógica aplicada:** parte da linha do tempo de atendimentos graves com eventos do tipo `"INTERCORRENCIA"`, cruza com `intercorrencias_atendimento` via `$lookup` usando `codigo_intercorrencia` (acelerado pelo índice único `uq_interc_codigo`) e consolida ocorrências, casos críticos e média de medidas adotadas por cor de risco e categoria.
* **Validação:** retornou os 15 principais cruzamentos, com destaque para `Laranja + DOR` (95 ocorrências, média de 2,71 medidas), `Laranja + ACESSO_VENOSO` (90 ocorrências), `Vermelho + DOR` (75 ocorrências) e concentrações de gravidade crítica em `Laranja + RESPIRATORIA` (72 ocorrências, 20 críticas, média 3,12 medidas), `Laranja + HEMODINAMICA` (60 ocorrências, 19 críticas) e `Vermelho + HEMODINAMICA` (49 ocorrências, 18 críticas).

### Pipeline 04 — Auditoria de acessos, conformidade LGPD e falhas de login por setor (`logs_auditoria`)

* **Pergunta respondida:** Como se distribuem o volume de ações no sistema, a quantidade de usuários ativos, os acessos a dados sensíveis (LGPD) e as falhas de autenticação entre os setores do hospital?
* **Estágios utilizados:** `$match` (`timestamp >= 2026-04-01`) -> `$group` -> `$project` -> `$sort`.
* **Lógica aplicada:** agrupa por `usuario.setor`, contabiliza profissionais distintos com `$addToSet` sobre `usuario.id_funcionario` e aplica contadores condicionais (`$cond`) para a tag `"lgpd"` e para `contexto_acesso.sucesso: false`.
* **Validação:** retornou todos os 10 setores do hospital, somando **27.704 ações**, **2.015 acessos LGPD** e **46 falhas de login**, liderados pelo **Pronto-Socorro** (12.755 ações, 69 usuários ativos, 2.015 acessos LGPD e 12 falhas de login) e pela **Enfermagem** (5.701 ações, 112 usuários ativos e 13 falhas de login).