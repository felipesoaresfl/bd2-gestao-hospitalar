# Documentação do Banco Relacional — MySQL (`gestao_emergencia_hospitalar`)

**SGBD:** MySQL / MariaDB (`InnoDB`, `utf8mb4`) · **Ferramenta:** MySQL Workbench · **Estrutura:** 37 tabelas

---

## 1. Modelagem Relacional e Normalização (1FN, 2FN e 3FN)

O banco relacional foi projetado com **37 tabelas** no motor `InnoDB` para eliminar redundâncias, evitar anomalias de inserção, atualização e exclusão e assegurar integridade referencial e de domínio (`PRIMARY KEY`, `FOREIGN KEY`, `UNIQUE` e `CHECK`):

* **1ª Forma Normal (1FN):** todos os atributos armazenam valores atômicos e cada tabela possui chave primária (`id_*` com `AUTO_INCREMENT` ou chave composta nas tabelas associativas `cargo_permissao` e `funcionario_permissao`). Grupos repetitivos e multivalorados foram isolados em entidades próprias (`contato`, `endereco`, `doenca`, `cirurgia`, `alergia`, `contraindicacao`, `sinais_vitais`, `solicitacao`, `ocupacao` e `transferencia`).
* **2ª Forma Normal (2FN):** todas as tabelas com chave primária simples possuem atributos dependentes exclusivamente da chave completa da entidade, e as tabelas associativas compostas (`cargo_permissao` e `funcionario_permissao`) não mantêm atributos dependentes de apenas parte da chave (`data_concessao` pertence ao vínculo completo entre funcionário e permissão).
* **3ª Forma Normal (3FN):** atributos não-chave não possuem dependências transitivas:
  * Dados de **convênio** (`registro_ans`, `telefone`, `status`) ficam isolados em `convenio`, referenciados por `paciente.id_convenio`.
  * **Setores** (`setor`), **cargos** (`cargo`) e **catálogos clínicos** (`procedimento`, `tipo_exame`, `exame`, `insumo`, `estoque`, `status_atendimento`, `classificacao_risco`, `local`) ficam em tabelas de domínio próprias, evitando repetição textual nas tabelas transacionais.
  * **Saldo de estoque** não é armazenado como coluna redundante em `insumo` (apenas `estoque_minimo` como parâmetro de alerta), sendo calculado dinamicamente a partir dos lançamentos em `movimentacao_estoque`.

---

## 2. Carga de Dados e Operações DML (`mysql/dml/`)

### 2.1 Volume de registros carregados
A carga inicial (`01_convenio.sql` a `37_alta.sql`) povoa as 37 tabelas respeitando a ordem de dependência das chaves estrangeiras. Na análise de estatísticas (`ANALYZE TABLE` / `EXPLAIN`) das tabelas principais e de domínio, os volumes registrados foram:

| Tabela | Registros apurados | Papel no modelo |
|---|---|---|
| `atendimento` | 2.201 | Registros de entrada e passagem pelo pronto-socorro |
| `triagem` | 2.179 | Classificações de risco realizadas pela enfermagem |
| `alta` | 2.137 | Desfechos clínicos (alta médica, evasão, óbito, transferência) |
| `paciente` | 1.802 | Pacientes identificados cadastrados |
| `internacao` | 323 | Internações clínicas, cirúrgicas e de UTI |
| `insumo` | 80 | Catálogo de medicamentos e materiais hospitalares |
| `leito` | 65 | Leitos distribuídos entre os setores/locais do hospital |
| `tipo_exame` | 6 | Categorias de exames laboratoriais e de imagem |
| `classificacao_risco` | 5 | Protocolo de Manchester (Vermelho, Laranja, Amarelo, Verde, Azul) |

*(Somadas às tabelas filhas de maior granularidade — `sinais_vitais`, `solicitacao`, `resultado_exame`, `movimentacao_estoque`, `registro_ponto`, `ocupacao` e itens de `historico_clinico` —, a base ultrapassa o volume mínimo de 30.000 registros exigido pelo projeto.)*

### 2.2 Operações do dia a dia (`mysql/dml/operacoes/`)
Para simular rotinas reais do pronto-socorro sem depender de IDs fixos, os 11 scripts localizam os registros por chaves naturais (CPF, login, nome do local, cor da classificação) e gerenciam o `SQL_SAFE_UPDATES` do Workbench:

| # | Arquivo | Operação | Cenário hospitalar simulado |
|---|---|---|---|
| **01** | `01_insert_chegada_de_paciente.sql` | `INSERT` | Chegada de paciente novo: grava cadastro, histórico clínico, alergia, contato, endereço, atendimento, triagem e sinais vitais. |
| **02** | `02_insert_update_identificacao_de_desconhecido.sql` | `INSERT` + `UPDATE` | Família identifica o paciente provisório `"Desconhecido 116"`: cria o paciente definitivo e vincula ao cadastro provisório e ao atendimento. |
| **03** | `03_update_status_pos_triagem.sql` | `UPDATE` | Atualiza o status do atendimento após a triagem para `"Aguardando atendimento médico"`. |
| **04** | `04_update_liberacao_de_leitos_higienizados.sql` | `UPDATE` | Libera leitos (`status = 'L'`) após a conclusão da higienização. |
| **05** | `05_update_reajuste_tabela_de_procedimentos.sql` | `UPDATE` | Aplica reajuste percentual de 4,5% nos valores da tabela `procedimento`. |
| **06** | `06_update_retorno_de_enfermeira_afastada.sql` | `UPDATE` | Reativa o cadastro funcional de enfermeira que retornou de afastamento. |
| **07** | `07_update_retorno_de_equipamentos_da_uti.sql` | `UPDATE` | Retorna equipamentos da UTI para status operacional após manutenção. |
| **08** | `08_delete_permissoes_extras_de_desligados.sql` | `DELETE` | Remove permissões individuais (`funcionario_permissao`) de colaboradores desligados. |
| **09** | `09_delete_contatos_pessoais_de_ex_funcionarios.sql` | `DELETE` | Exclui contatos pessoais vinculados a ex-funcionários inativos. |
| **10** | `10_delete_baixa_de_equipamentos_inativos.sql` | `DELETE` | Dá baixa definitiva em equipamentos marcados como inativos/descartados. |
| **11** | `11_delete_solicitacoes_de_exame_duplicadas.sql` | `DELETE` | Remove solicitações de exame canceladas por lançamento duplicado. |

---

## 3. Consultas Analíticas (`mysql/consultas/01` a `12`)

As 12 consultas respondem a indicadores operacionais e clínicos da gestão hospitalar utilizando filtros (`WHERE`), agrupamentos (`GROUP BY`, `HAVING`), funções de agregação (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`), cálculos temporais (`TIMESTAMPDIFF`) e subconsultas:

| # | Arquivo | Pergunta de negócio respondida | Recursos SQL empregados |
|---|---|---|---|
| **01** | `01_atendimentos_por_mes_e_forma_de_chegada.sql` | Quantos atendimentos ocorrem por mês e qual o percentual que chega por resgate (SAMU/bombeiros) vs. demanda espontânea? | `DATE_FORMAT`, `COUNT`, `SUM` + `CASE WHEN`, `GROUP BY`, `ORDER BY` |
| **02** | `02_classificacao_de_risco_e_espera_ate_a_triagem.sql` | Como se distribui a classificação de risco e qual o tempo médio e máximo de espera até a triagem? | `INNER JOIN`, subconsulta escalar, `TIMESTAMPDIFF(MINUTE, ...)`, `AVG`, `MAX` |
| **03** | `03_ocupacao_atual_dos_leitos_por_local.sql` | Qual a taxa atual de ocupação dos leitos (`O`, `L`, `H`/`M`) por setor/local do hospital? | `INNER JOIN`, `SUM` + `CASE WHEN`, `ROUND`, `GROUP BY`, `ORDER BY` |
| **04** | `04_diagnosticos_mais_frequentes_nas_altas.sql` | Quais os 10 diagnósticos (`cid_final`) mais frequentes nas altas médicas e qual a idade média dos pacientes? | `INNER JOIN`, `WHERE` (`IS NOT NULL`), subconsulta, `TIMESTAMPDIFF(YEAR, ...)`, `LIMIT 10` |
| **05** | `05_exames_mais_pedidos_e_taxa_de_alteracao.sql` | Quais exames com ao menos 100 laudos possuem maior taxa de resultados alterados (`A`) ou críticos (`C`)? | Múltiplos `INNER JOIN`, `SUM` + `CASE WHEN`, `GROUP BY`, `HAVING COUNT(*) >= 100` |
| **06** | `06_pacientes_que_mais_retornaram_ao_pronto_socorro.sql` | Quais pacientes retornaram 3 ou mais vezes ao pronto-socorro, com data da primeira e última visita? | `INNER JOIN`, `MIN`/`MAX`, `TIMESTAMPDIFF`, `GROUP BY`, `HAVING COUNT(*) >= 3` |
| **07** | `07_tempo_de_permanencia_por_tipo_de_internacao.sql` | Qual o tempo médio, mínimo e máximo de permanência (em dias) nas internações encerradas (`Clínica`, `Cirúrgica`, `UTI`)? | `CASE`, `WHERE status = 'E'`, `TIMESTAMPDIFF(HOUR, ...)`, `AVG`/`MIN`/`MAX` |
| **08** | `08_insumos_mais_consumidos_e_saldo_atual.sql` | Quais os 15 insumos mais consumidos em atendimentos (`tipo = 'S'`) e qual o saldo atual disponível no hospital? | `INNER JOIN`, subconsulta correlacionada em `movimentacao_estoque`, `GROUP BY`, `LIMIT 15` |
| **09** | `09_casos_graves_de_pacientes_alergicos_a_medicamento.sql` | Quais atendimentos de prioridade alta (`prioridade <= 2`) envolvem pacientes com alergia medicamentosa moderada ou grave? | `INNER JOIN`, subconsulta com `IN` em `historico_clinico` e `alergia` (`tipo = 'M'`) |
| **10** | `10_afericoes_com_sinais_vitais_de_alerta.sql` | Quais as 30 aferições mais recentes com sinais vitais críticos (saturação `< 90`, pressão sistólica `< 90` ou febre `>= 39.0`)? | `INNER JOIN`, `LEFT JOIN`, `COALESCE`, `WHERE ... OR ...`, `ORDER BY ... DESC LIMIT 30` |
| **11** | `11_atendimentos_por_convenio.sql` | Qual o volume de atendimentos, pacientes distintos e participação percentual por convênio e SUS/particular? | `INNER JOIN`, `LEFT JOIN`, `COALESCE`, `COUNT(DISTINCT ...)`, subconsulta escalar |
| **12** | `12_tempo_medio_ate_o_laudo_por_tipo_de_exame.sql` | Qual o tempo médio, mínimo e máximo (em horas) até a liberação do laudo nos exames urgentes (`prioridade = 'U'`) com média acima de 1 hora? | Múltiplos `INNER JOIN`, `TIMESTAMPDIFF(MINUTE, ...)`, `HAVING AVG(...) > 60` |

---

## 4. Consultas Focadas em Junções — JOINs (`mysql/consultas/joins/01` a `07`)

Os 7 scripts em `mysql/consultas/joins/` exploram junções entre múltiplas tabelas (`INNER JOIN` encadeado, `LEFT JOIN` para registros opcionais/provisórios, anti-join com `IS NULL` e combinação via `UNION`):

| # | Arquivo | Tipo de junção | Objetivo da consulta |
|---|---|---|---|
| **J01** | `01_inner_join_casos_vermelhos_da_chegada_a_alta.sql` | `INNER JOIN` (7 tabelas) | Rastreia casos de risco `'Vermelho'` desde a entrada até a alta, cruzando `atendimento`, `paciente`, `triagem`, `classificacao_risco`, `alta` e duas instâncias de `funcionario` (enfermeiro da triagem e médico da alta). |
| **J02** | `02_inner_join_laudos_criticos_e_quem_liberou.sql` | `INNER JOIN` + `LEFT JOIN` | Lista laudos críticos (`situacao = 'C'`), exame realizado, profissional responsável e cargo, resolvendo paciente cadastrado ou provisório via `COALESCE`. |
| **J03** | `03_left_join_pacientes_internados_agora_e_leito.sql` | `INNER JOIN` + `LEFT JOIN` | Exibe pacientes com internação ativa (`status = 'A'`), dias internado, médico responsável e leito/local atual (mantendo na listagem pacientes ainda aguardando alocação de leito). |
| **J04** | `04_left_join_exames_ainda_sem_resultado.sql` | `INNER JOIN` + `LEFT JOIN` | Identifica solicitações de exame ativas (`tipo = 'E'`, `status <> 'C'`) que ainda não possuem registro na tabela `resultado_exame` (`r.id_resultado IS NULL`). |
| **J05** | `05_inner_join_quem_pode_gerenciar_leitos.sql` | `INNER JOIN` + `UNION` | Consolida todos os funcionários ativos que possuem a permissão `'GERENCIAR_LEITOS'`, seja por herança do cargo (`cargo_permissao`) ou por concessão individual (`funcionario_permissao`). |
| **J06** | `06_inner_join_transferencias_para_outros_hospitais.sql` | `INNER JOIN` + `LEFT JOIN` | Lista transferências externas (`tipo = 'E'`) com identificação do paciente, motivo da internação, hospital de destino, justificativa e médico autorizador. |
| **J07** | `07_left_join_triagens_por_enfermeiro.sql` | `INNER JOIN` + `LEFT JOIN` | Apura a produtividade de triagens por enfermeiro (`'Enfermeiro'` e `'Enfermeiro coordenador'`), incluindo profissionais que ainda não realizaram triagens, além do total de casos graves (`prioridade <= 2`). |

---

## 5. Views (`mysql/views/`)

Foram criadas **5 Views** (`CREATE OR REPLACE VIEW`) para encapsular junções recorrentes entre tabelas clínicas, operacionais e de estoque, simplificando relatórios gerenciais e reutilizando regras de exibição (como resolução de pacientes identificados vs. provisórios via `COALESCE`):

| # | View (`arquivo`) | Tabelas envolvidas | Finalidade e recursos SQL |
|---|---|---|---|
| **V01** | `vw_atendimentos_detalhados` (`atendimentos_detalhados.sql`) | `atendimento`, `paciente`, `cadastro_provisorio`, `funcionario`, `status_atendimento`, `local`, `triagem`, `classificacao_risco` | Consolida a visão completa de cada passagem pelo pronto-socorro (identificando via `CASE` se o cadastro é `'Identificado'` ou `'Provisorio'`, status, local, risco e queixa). É reutilizada diretamente pela procedure `sp_consultar_atendimentos_periodo`. |
| **V02** | `vw_fila_classificacao_risco` (`fila_classificacao_risco.sql`) | `atendimento`, `triagem`, `classificacao_risco`, `paciente`, `cadastro_provisorio`, `funcionario` | Organiza a fila assistencial após a triagem, ordenando os pacientes por prioridade clínica (`cr.prioridade ASC`) e ordem de chegada na triagem (`t.data_hora ASC`), exibindo cor, tempo máximo de espera e enfermeiro responsável. |
| **V03** | `vw_solicitacoes_detalhadas` (`solicitacoes_detalhadas.sql`) | `solicitacao`, `atendimento`, `paciente`, `cadastro_provisorio`, `funcionario`, `procedimento`, `exame`, `insumo` | Unifica em uma única consulta as solicitações de Procedimento (`'P'`), Exame (`'E'`) e Insumo (`'I'`), resolvendo dinamicamente o nome do item solicitado por meio de `COALESCE(pr.nome, ex.nome, i.nome)`. |
| **V04** | `vw_saldo_estoque` (`saldo_estoque.sql`) | `estoque`, `insumo`, `movimentacao_estoque` | Cruza todos os estoques e insumos (`CROSS JOIN` com `LEFT JOIN` nas movimentações) e calcula `total_entradas`, `total_saidas` e `saldo_atual` por unidade de armazenamento, permitindo comparar o saldo real com `estoque_minimo`. |
| **V05** | `vw_internacoes_leitos` (`internacoes_e_leitos.sql`) | `internacao`, `atendimento`, `paciente`, `cadastro_provisorio`, `funcionario`, `ocupacao`, `leito`, `local` | Acompanha o histórico e a situação atual das internações junto com a alocação de leito e setor (`LEFT JOIN` em `ocupacao` e `leito` para preservar internações ainda sem leito vinculado). |

---

## 6. Stored Procedures (`mysql/procedures/`)

Foram implementadas **3 Stored Procedures** para encapsular consultas parametrizadas e transações críticas com validação de regras de negócio via `SIGNAL SQLSTATE '45000'`:

1. **`sp_consultar_atendimentos_periodo(IN p_data_inicio DATE, IN p_data_fim DATE)`**
   * **Finalidade:** recupera os atendimentos detalhados (via `vw_atendimentos_detalhados`) realizados dentro de um intervalo fechado de datas.
   * **Validação:** bloqueia execução caso alguma data seja nula ou `p_data_inicio > p_data_fim` (`'Informe um periodo de datas valido'`).
2. **`sp_registrar_movimentacao_estoque(IN p_id_insumo, p_id_estoque, p_id_funcionario, p_tipo, p_quantidade, p_lote, p_data_validade, p_id_solicitacao)`**
   * **Finalidade:** padroniza o registro de entradas (`'E'`), saídas (`'S'`) e ajustes (`'A'`) na tabela `movimentacao_estoque`.
   * **Validação:** exige `p_quantidade >= 1` e `p_tipo IN ('E', 'S', 'A')`; nas saídas, delega a verificação de saldo disponível à trigger `trg_validar_saida_estoque`.
3. **`sp_encerrar_internacao(IN p_id_internacao INT)`**
   * **Finalidade:** encerra atomicamente uma internação ativa (`status = 'E'`, preenchendo `data_hora_saida`) e fecha a ocupação aberta correspondente em `ocupacao`.
   * **Controle transacional:** utiliza `START TRANSACTION`, `SELECT ... FOR UPDATE` para evitar concorrência, `EXIT HANDLER FOR SQLEXCEPTION` com `ROLLBACK` e bloqueia internações inexistentes ou já encerradas. O fechamento da ocupação dispara automaticamente a trigger `trg_liberar_leito`.

---

## 7. Triggers (`mysql/triggers/`)

Foram implementadas **3 Triggers** para garantir consistência automática no controle de estoque e no ciclo de vida dos leitos hospitalares:

1. **`trg_validar_saida_estoque` (`BEFORE INSERT ON movimentacao_estoque`)**
   * **Regra:** sempre que `NEW.tipo = 'S'`, calcula o saldo atual do insumo naquele estoque específico (`SUM` de entradas `'E'` menos saídas `'S'`). Se `NEW.quantidade > v_saldo`, cancela a inserção com `SIGNAL SQLSTATE '45000'` (`'Estoque insuficiente para realizar a saida'`), impedindo estoque negativo.
2. **`trg_ocupar_leito` (`AFTER INSERT ON ocupacao`)**
   * **Regra:** ao inserir uma nova alocação em `ocupacao`, atualiza automaticamente o registro correspondente em `leito` para `status = 'O'` (Ocupado).
3. **`trg_liberar_leito` (`AFTER UPDATE ON ocupacao`)**
   * **Regra:** quando `OLD.data_hora_saida IS NULL` e `NEW.data_hora_saida IS NOT NULL`, verifica se não existe nenhuma outra ocupação ativa (`data_hora_saida IS NULL`) para aquele `id_leito` e altera o status do leito para `'L'` (Livre).

---

## 8. Estratégia de Indexação e Análise `EXPLAIN` (`mysql/indices/`)

Além dos índices automáticos criados pelo `InnoDB` para `PRIMARY KEY`, `UNIQUE` e `FOREIGN KEY`, foram criados **10 índices compostos e de cobertura** em `02_criar_indices.sql` para eliminar varreduras completas (`ALL`) e permitir resolução diretamente no índice (`Using index`):

1. `idx_atendimento_paciente_entrada` em `atendimento (id_paciente, data_hora_entrada)`
2. `idx_atendimento_entrada_tipo` em `atendimento (data_hora_entrada, tipo_entrada)`
3. `idx_triagem_class_atend_data` em `triagem (id_classificacao, id_atendimento, data_hora)`
4. `idx_alta_tipo_cid_atend` em `alta (tipo, cid_final, id_atendimento)`
5. `idx_internacao_status_tipo_datas` em `internacao (status, tipo, data_hora_entrada, data_hora_saida)`
6. `idx_movest_insumo_tipo_solic_qtd` em `movimentacao_estoque (id_insumo, tipo, id_solicitacao, quantidade)`
7. `idx_alergia_tipo_grav_hist` em `alergia (tipo, gravidade, id_historico)`
8. `idx_sinais_data_alerta` em `sinais_vitais (data_hora, saturacao_o2, pressao_sistolica, temperatura, id_atendimento)`
9. `idx_solicitacao_prio_exame_data` em `solicitacao (prioridade, id_exame, data_hora)`
10. `idx_resultado_solic_sit_data` em `resultado_exame (id_solicitacao, situacao, data_hora_resultado)`

### 8.1 Comparativo `EXPLAIN` (Antes x Depois)

| Consulta | Tabela analisada | `type` (Antes) | `key` (Antes) | `rows` (Antes) | `Extra` (Antes) | `type` (Depois) | `key` (Depois) | `rows` (Depois) | `Extra` (Depois) |
|---|---|---|---|---|---|---|---|---|---|
| **01** | `atendimento` | `ALL` | *(nenhum)* | 2.201 | `Using temporary; Using filesort` | `index` | `idx_atendimento_entrada_tipo` | 2.201 | `Using index; Using temporary; Using filesort` |
| **02** | `triagem` | `ref` | `fk_triagem_classificacao` | 217 | *(vazio)* | `ref` | `idx_triagem_class_atend_data` | 217 | `Using index` |
| **03** | `leito` | `ALL` | *(nenhum)* | 65 | `Using temporary; Using filesort` | `ALL` | *(nenhum)* | 65 | `Using temporary; Using filesort` |
| **04** | `alta` (subconsulta) / `atendimento` | `ALL` | *(nenhum)* | 2.137 | `Using where; Using temporary; Using filesort` | `ref` | `idx_alta_tipo_cid_atend` / `idx_atendimento_paciente_entrada` | 2.076 / 1 | `Using where; Using index` |
| **05** | `resultado_exame` | `eq_ref` | `id_solicitacao` | 1 | *(vazio)* | `eq_ref` | `id_solicitacao` *(avaliou `idx_resultado_solic_sit_data`)* | 1 | *(vazio)* |
| **06** | `atendimento` | `ALL` | *(nenhum)* | 2.201 | `Using where; Using temporary; Using filesort` | `ref` | `idx_atendimento_paciente_entrada` | 1 | `Using index` |
| **07** | `internacao` | `ALL` | *(nenhum)* | 323 | `Using where; Using temporary; Using filesort` | `ref` | `idx_internacao_status_tipo_datas` | 312 | `Using where; Using index; Using temporary; Using filesort` |
| **08** | `movimentacao_estoque` (`m` / `m2`) | `ref` | `fk_movimentacao_estoque_insumo` | 47 / 47 | `Using where` / *(vazio)* | `ref` | `idx_movest_insumo_tipo_solic_qtd` | 18 / 47 | `Using where; Using index` / `Using index` |
| **09** | `alergia`, `atendimento`, `triagem` | `ref` | `fk_triagem_classificacao` / `fk_alergia_historico` | 217 / 1 | `Using index condition` | `range` / `ref` | `idx_alergia_tipo_grav_hist`, `idx_atendimento_paciente_entrada`, `idx_triagem_class_atend_data` | 174 / 1 / 1 | `Using index` nas 3 tabelas |
| **10** | `atendimento` / `sinais_vitais` | `ALL` / `ref` | *(nenhum)* / `fk_sinais_vitais_atendimento` | 2.201 / 1 | `Using temporary; Using filesort` | `ALL` / `ref` | *(nenhum)* / `fk_sinais_vitais_atendimento` | 2.201 / 1 | `Using temporary; Using filesort` |
| **11** | `atendimento` | `ref` / `range` | `fk_atendimento_paciente` | 1 / 2.186 | `Using index` | `ref` / `range` | `idx_atendimento_paciente_entrada` | 1 / 2.186 | `Using index` |
| **12** | `solicitacao` | `ref` | `fk_solicitacao_exame` | 157 | `Using where` | `ref` | `idx_solicitacao_prio_exame_data` | 85 | `Using where; Using index` |

### 8.2 Diagnóstico dos ganhos obtidos
* **Eliminação de Full Table Scans (`ALL`):** as consultas **01** (`atendimento`), **04** (`alta` e `atendimento`), **06** (`atendimento`) e **07** (`internacao`) deixaram de ler as tabelas completas e passaram a navegar pelos índices compostos criados. Na Consulta **06**, a leitura em `atendimento` caiu de **2.201 linhas** (`ALL`) para **1 linha por paciente** (`ref` + `Using index`).
* **Índices de cobertura (`Using index`) e redução de linhas examinadas:** na Consulta **08**, a leitura de `movimentacao_estoque` caiu de **47 para 18 linhas** por insumo, resolvendo tanto a agregação principal quanto a subconsulta de saldo sem acessar os registros completos da tabela. Na Consulta **12**, `solicitacao` caiu de **157 para 85 linhas** por exame filtrando `prioridade = 'U'` dentro do índice. Na Consulta **09**, o otimizador passou a filtrar seletivamente por `idx_alergia_tipo_grav_hist` e encadeou três índices novos com `Using index`.
* **Comportamento esperado em tabelas pequenas e predicados `OR`:** na Consulta **03** (`leito`), a tabela tem apenas 65 linhas e o otimizador opta pela leitura direta em memória; na Consulta **05**, a chave única `id_solicitacao` já realiza acesso 1:1 (`eq_ref`, `rows = 1`); e na Consulta **10**, a combinação de três condições com `OR` em colunas distintas (`saturacao_o2 < 90 OR pressao_sistolica < 90 OR temperatura >= 39.0`) impede uma varredura única por faixa na B-Tree.

---

## 9. Controle de Acesso — DCL (`mysql/dcl/01_dcl_perfis.sql`)

O controle de permissões aplica o princípio do menor privilégio com **4 perfis** locais (`@'localhost'`) e restrição por coluna na tabela `funcionario` para proteger `cpf` e `senha`:

* **`dba_emergencia`:** `ALL PRIVILEGES` sobre `gestao_emergencia_hospitalar.*` (administração completa do esquema).
* **`medico_emergencia`:** leitura de prontuário, triagem, sinais vitais, exames e leitos; gravação em `atendimento` (`UPDATE`), `internacao`, `transferencia`, `alta` e itens de `historico_clinico` (`doenca`, `alergia`, `cirurgia`, `contraindicacao`); leitura em `funcionario` restrita a `(id_funcionario, id_cargo, nome, registro_profissional, status)`. Após `REVOKE`, não possui `INSERT`/`UPDATE` em `solicitacao`.
* **`recepcao_emergencia`:** `SELECT`, `INSERT` e `UPDATE` em `paciente`, `cadastro_provisorio`, `contato` e `endereco`; `SELECT` em tabelas de apoio e `SELECT, INSERT` em `atendimento` (após `REVOKE UPDATE`).
* **`analista_emergencia`:** acesso somente leitura (`SELECT`) às tabelas utilizadas nas 12 consultas analíticas e leitura em `funcionario` restrita a `(id_funcionario, id_cargo, nome, data_admissao, status)`. Após os `REVOKE`s, não possui acesso a `transferencia` nem permissão `EXECUTE` em procedures.