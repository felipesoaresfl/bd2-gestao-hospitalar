# Indexação no MongoDB (Item 3.7)

**Banco:** `gestao_emergencia_hospitalar` · **SGBD:** MongoDB · **Collections:** 4 · **Total validado:** 106.346 documentos · **Índices criados:** 14 (12 compostos + 2 únicos)

---

## 1. Para que servem os índices no projeto

Sem índices adicionais, qualquer consulta que não filtre pelo `_id` obriga o MongoDB a executar um **`COLLSCAN`** (varredura completa da collection), lendo todos os documentos um por um e, quando há `.sort()`, ordenando os resultados em memória (`SORT`). Em um ambiente hospitalar com telemetria contínua e auditoria crescente, esse padrão degrada rapidamente o tempo de resposta.

Os índices criados estruturam os campos mais consultados em árvores **B-Tree** ordenadas, permitindo ao banco:

* **Substituir `COLLSCAN` por `IXSCAN`:** localizar apenas o trecho relevante da collection, reduzindo drasticamente o número de documentos examinados (`docsExaminados`).
* **Eliminar `SORT` em memória:** quando o índice respeita a mesma ordem e direção do `.sort()`, o MongoDB já percorre os registros ordenados e interrompe a leitura assim que atinge o `.limit()`.
* **Garantir integridade referencial e acelerar `$lookup`:** como o MongoDB não cria chaves únicas automaticamente além do `_id`, índices `unique` impedem duplicidade de identificadores de negócio e evitam varreduras completas durante cruzamentos entre collections.

### Estratégia aplicada: Regra ESR e índices Multikey

Todos os índices compostos foram projetados seguindo a regra **ESR (*Equality, Sort, Range*)**:

1. **E (*Equality*):** campos filtrados por igualdade exata aparecem primeiro.
2. **S (*Sort*):** campos usados na ordenação vêm em seguida, na mesma direção (`1` ou `-1`) da consulta.
3. **R (*Range*):** campos de intervalo (`$lt`, `$gt`, `$in`) ou filtros secundários fecham o índice.

Nos campos que armazenam arrays (`alertas_disparados`, `tags` e `eventos`), o MongoDB cria automaticamente índices **multikey** (uma entrada de índice por elemento do array), respeitando a restrição de nunca combinar dois arrays distintos no mesmo índice composto.

> **Compromisso de escrita (*trade-off*):** cada índice adicional consome espaço em disco/RAM e adiciona custo de manutenção a operações de `INSERT` e `UPDATE`. Por isso, em produção, collections de escrita intensa como `telemetria_sinais_vitais` e `logs_auditoria` exigem revisão periódica para manter apenas os índices efetivamente usados pelas consultas críticas.

---

## 2. Organização dos scripts e como executar

Todos os scripts de indexação estão centralizados na pasta `mongodb/indices/`:

| Arquivo | Finalidade |
|---|---|
| `01_criar_indices.mongodb.js` | Cria os 12 índices compostos voltados às consultas de leitura e os 2 índices únicos de integridade, exibindo a listagem final por collection. |
| `02_explain_consultas.mongodb.js` | Executa `explain("executionStats")` sobre as 12 consultas de `mongodb/consultas/01_consultas.mongodb.js` e imprime estágios, índice utilizado, documentos/chaves examinados e tempo em milissegundos. |
| `03_remover_indices.mongodb.js` | Remove apenas os 14 índices criados pelo script `01`, preservando os dados e o índice padrão `_id`, permitindo repetir o experimento comparativo. |

### Roteiro de validação

1. Executar `02_explain_consultas.mongodb.js` **antes** da criação dos índices (ou com `var FORCAR_COLLSCAN = true;` para simular varredura completa).
2. Executar `01_criar_indices.mongodb.js` e confirmar `OK` nos 14 índices.
3. Executar `02_explain_consultas.mongodb.js` **depois** da criação dos índices (com `var FORCAR_COLLSCAN = false;`) e comparar os resultados.

---

## 3. Volumetria das collections avaliadas

| Collection | Documentos na validação | Perfil de uso |
|---|---:|---|
| `telemetria_sinais_vitais` | 75.017 | Alta taxa de inserção (leituras de monitores multiparamétricos) |
| `logs_auditoria` | 27.708 | Trilha imutável (*append-only*) de ações e conformidade LGPD |
| `linha_tempo_atendimento` | 2.201 | Documento consolidado 1:1 por atendimento hospitalar |
| `intercorrencias_atendimento` | 1.420 | Eventos clínicos com atualização de status durante o plantão |
| **Total** | **106.346** | — |

---

## 4. Índices criados e justificativas

### 4.1 `telemetria_sinais_vitais` (3 índices)

| Índice | Chave | Consulta beneficiada | Justificativa técnica |
|---|---|---|---|
| `idx_telem_tipolocal_spo2_ts_fc` | `{ "localizacao.tipo_local": 1, "sinais.saturacao_o2_pct": 1, "timestamp": -1, "sinais.frequencia_cardiaca_bpm": 1 }` | Consulta 01 | Igualdade em `tipo_local = "U"`, seguido da ordenação por saturação crescente e data decrescente. O filtro `frequencia_cardiaca_bpm > 110` é avaliado diretamente nas chaves do índice antes do `FETCH`. |
| `idx_telem_alerta_sev_cod_ts` | `{ "alertas_disparados.severidade": 1, "alertas_disparados.codigo": 1, "timestamp": -1 }` | Consulta 02 | Índice **multikey** que atende ao `$elemMatch` (severidade `"CRITICA"` + código `"HIPOXEMIA"` ou `"HIPOTENSAO"`). O MongoDB executa dois `IXSCAN` já ordenados por `timestamp` e os combina via `SORT_MERGE`. |
| `idx_telem_identificado_bateria_ts` | `{ "paciente_ref.identificado": 1, "dispositivo.bateria_pct": 1, "timestamp": -1 }` | Consulta 03 | Isola pacientes não identificados (`identificado = false`) já ordenados pela menor bateria e data mais recente, permitindo aplicar o filtro `$or` sobre um subconjunto reduzido. |

### 4.2 `logs_auditoria` (3 índices)

| Índice | Chave | Consulta beneficiada | Justificativa técnica |
|---|---|---|---|
| `idx_log_acao_tags_ts` | `{ "acao": 1, "tags": 1, "timestamp": -1 }` | Consulta 04 | Índice **multikey** que combina `acao = "SELECT"` e a presença das tags `"dado_sensivel"` e `"lgpd"`, entregando os registros ordenados por data decrescente. |
| `idx_log_acao_sucesso_ts` | `{ "acao": 1, "contexto_acesso.sucesso": 1, "timestamp": -1 }` | Consulta 05 | Combina as duas igualdades de alta seletividade (`acao = "LOGIN"` e `sucesso = false`) com o `sort` por `timestamp: -1`. |
| `idx_log_acao_ts_modulo_setor` | `{ "acao": 1, "timestamp": -1, "modulo": 1, "usuario.setor": 1 }` | Consulta 06 | Aplica estritamente a regra **ESR**: após a igualdade `acao = "UPDATE"`, posiciona `timestamp: -1` antes dos campos com `$in` (`modulo` e `usuario.setor`), evitando `SORT` em memória. |

### 4.3 `intercorrencias_atendimento` (4 índices)

| Índice | Chave | Consulta / uso beneficiado | Justificativa técnica |
|---|---|---|---|
| `idx_interc_resolucao_data` | `{ "data_hora_resolucao": 1, "data_hora": -1 }` | Consulta 07 | Aproveita a altíssima seletividade de `data_hora_resolucao: null` (apenas ocorrências ainda abertas) já ordenadas pela data mais recente. |
| `idx_interc_tags_data_categoria` | `{ "tags": 1, "data_hora": -1, "categoria": 1 }` | Consulta 08 | Índice **multikey** no padrão **ESR**: igualdade em `tags = "uti"`, ordenação por `data_hora: -1` e filtro `$in` em `categoria`. Reduz os candidatos antes da avaliação de `$size: 4` no documento. |
| `idx_interc_paciente_data` | `{ "id_paciente": 1, "data_hora": -1 }` | Consulta 09 | Isola intercorrências de pacientes não identificados (`id_paciente: null`) já na ordem de `data_hora: -1`, evitando varredura total antes do filtro `$nor`. |
| `uq_interc_codigo` *(unique)* | `{ "codigo_intercorrencia": 1 }` | Integridade + Pipeline 03 (item 3.6) | Garante unicidade do código da intercorrência e indexa a chave estrangeira lógica utilizada no estágio `$lookup` a partir de `linha_tempo_atendimento`. |

### 4.4 `linha_tempo_atendimento` (4 índices)

| Índice | Chave | Consulta / uso beneficiado | Justificativa técnica |
|---|---|---|---|
| `idx_lt_encerr_prio_entrada_eventos` | `{ "data_hora_encerramento": 1, "classificacao_risco.prioridade": 1, "data_hora_entrada": 1, "total_eventos": 1 }` | Consulta 10 | Filtra atendimentos em aberto (`data_hora_encerramento: null`), entrega resultados ordenados por prioridade e entrada, e avalia `total_eventos >= 5` no próprio índice. |
| `idx_lt_evtipo_situacao_total_entrada` | `{ "eventos.tipo": 1, "eventos.detalhes.situacao": 1, "total_eventos": -1, "data_hora_entrada": -1 }` | Consulta 11 | Índice **multikey** sobre o array `eventos` para o `$elemMatch` de exames críticos (`RESULTADO_EXAME` + situação `"C"`), alinhado ao `sort` por `total_eventos` e `data_hora_entrada`. |
| `idx_lt_prio_entrada` | `{ "classificacao_risco.prioridade": 1, "data_hora_entrada": -1 }` | Consulta 12 | Como `$regex` com alternância e flag case-insensitive (`i`) não utiliza índice diretamente, este índice elimina o `SORT` percorrendo os atendimentos do maior risco para o menor até completar o `limit(10)`. |
| `uq_lt_id_atendimento` *(unique)* | `{ "id_atendimento": 1 }` | Integridade relacional (MySQL ↔ MongoDB) | Garante a cardinalidade 1:1 entre cada linha do tempo no MongoDB e a tabela `atendimento` no MySQL. |

---

## 5. Resultados comparativos (`explain("executionStats")`)

Os resultados abaixo foram coletados diretamente no MongoDB com a massa completa de **106.346 documentos**, executando `02_explain_consultas.mongodb.js` antes (somente `_id`) e imediatamente após a criação dos 14 índices.

| Consulta | Collection | Plano (Antes) | Docs examinados (Antes) | Tempo (Antes) | Plano (Depois) | Docs examinados (Depois) | Tempo (Depois) | Redução de docs |
|---|---|---|---:|---:|---|---:|---:|---:|
| **01** | `telemetria_sinais_vitais` | `COLLSCAN` | 75.017 | 1.879 ms | `IXSCAN` (`idx_telem_tipolocal_spo2_ts_fc`) | **10** *(82 chaves)* | **125 ms** | **-99,99%** |
| **02** | `telemetria_sinais_vitais` | `COLLSCAN` | 75.017 | 143 ms | `IXSCAN` x2 + `SORT_MERGE` (`idx_telem_alerta_sev_cod_ts`) | **10** *(11 chaves)* | **88 ms** | **-99,99%** |
| **03** | `telemetria_sinais_vitais` | `COLLSCAN` | 75.017 | 171 ms | `IXSCAN` (`idx_telem_identificado_bateria_ts`) | **231** *(231 chaves)* | **12 ms** | **-99,69%** |
| **04** | `logs_auditoria` | `COLLSCAN` | 27.708 | 458 ms | `IXSCAN` (`idx_log_acao_tags_ts`) | **11** | **191 ms** | **-99,96%** |
| **05** | `logs_auditoria` | `COLLSCAN` | 27.708 | 35 ms | `IXSCAN` (`idx_log_acao_sucesso_ts`) | **10** | **2 ms** | **-99,96%** |
| **06** | `logs_auditoria` | `COLLSCAN` | 27.708 | 77 ms | `IXSCAN` (`idx_log_acao_ts_modulo_setor`) | **10** | **11 ms** | **-99,96%** |
| **07** | `intercorrencias_atendimento` | `COLLSCAN` | 1.420 | 72 ms | `IXSCAN` (`idx_interc_resolucao_data`) | **15** | **38 ms** | **-98,94%** |
| **08** | `intercorrencias_atendimento` | `COLLSCAN` | 1.420 | 3 ms | `IXSCAN` (`idx_interc_tags_data_categoria`) | **25** | **95 ms\*** | **-98,24%** |
| **09** | `intercorrencias_atendimento` | `COLLSCAN` | 1.420 | 3 ms | `IXSCAN` (`idx_interc_paciente_data`) | **31** | **29 ms\*** | **-97,82%** |
| **10** | `linha_tempo_atendimento` | `COLLSCAN` | 2.201 | 376 ms | `IXSCAN` (`idx_lt_encerr_prio_entrada_eventos`) | **10** | **297 ms\*** | **-99,55%** |
| **11** | `linha_tempo_atendimento` | `COLLSCAN` | 2.201 | 134 ms | `IXSCAN` (`idx_lt_evtipo_situacao_total_entrada`) | **10** | **13 ms** | **-99,55%** |
| **12** | `linha_tempo_atendimento` | `COLLSCAN` | 2.201 | 150 ms | `IXSCAN` (`idx_lt_prio_entrada`) | **55** | **1 ms** | **-97,50%** |
| **Total** | **12 consultas** | **12 `COLLSCAN`** | **319.038** | **3.501 ms** | **12 `IXSCAN`** | **428** | **902 ms** | **-99,87%** |

---

## 6. Análise técnica dos resultados

* **Eliminação total de varreduras completas:** todas as 12 consultas migraram de `COLLSCAN` para `IXSCAN`, reduzindo o volume agregado de documentos lidos de **319.038 para apenas 428 documentos** (queda global de **99,87%**).
* **Filtragem no índice antes do `FETCH` (Consulta 01):** o banco inspecionou 82 entradas no índice `idx_telem_tipolocal_spo2_ts_fc`, descartou pelo próprio índice os registros com frequência cardíaca fora do critério e acessou o disco apenas para os **10 documentos exatos** retornados, reduzindo o tempo de 1.879 ms para 125 ms.
* **Uso de `SORT_MERGE` em `$in` com multikey (Consulta 02):** em vez de ordenar resultados em memória, o otimizador abriu dois `IXSCAN` já ordenados por `timestamp` decrescente (um para `HIPOXEMIA` e outro para `HIPOTENSAO`), mesclou os fluxos via `SORT_MERGE` e interrompeu a execução no `LIMIT 10`, examinando somente 11 chaves e 10 documentos.
* **Comportamento de operadores não indexáveis (Consultas 03, 08, 09 e 12):** essas consultas leram entre 25 e 231 documentos (ainda com redução acima de 97,5%) porque aplicam filtros adicionais no estágio de `FETCH` (`$or`, `$size: 4`, `$nor` e `$regex` case-insensitive). O índice garantiu que esses filtros fossem avaliados já na ordem final do `sort()`, parando logo ao completar o `limit()`.
* **Nota sobre tempos da primeira execução (`*` nas Consultas 08, 09 e 10):** a medição registrada na tabela corresponde à primeira execução imediatamente após a criação dos índices (*cache frio*). Nessa primeira passagem, o *Query Planner* do MongoDB avalia planos candidatos entre os novos índices e carrega as páginas do índice na memória RAM — efeito que se destaca especialmente em collections menores (1.420 e 2.201 documentos). Nas execuções subsequentes (com o plano e os índices em cache), a latência estabiliza em poucos milissegundos, mantendo a redução estrutural de `docsExaminados` que garante escalabilidade para milhões de registros.