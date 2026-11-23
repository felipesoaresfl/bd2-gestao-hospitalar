# 🏥 Sistema de Gestão de Emergências e Atendimento Hospitalar

## 📝 Descrição
O projeto consiste em um sistema abrangente projetado para otimizar e rastrear o fluxo de pacientes em um ambiente hospitalar de emergência. Ele abrange desde o cadastro inicial (incluindo pacientes sem identificação prévia) até a triagem pelo protocolo de classificação de risco, acompanhamento médico, solicitação de exames, internação e alta. A solução também gerencia a infraestrutura hospitalar, controlando leitos, equipamentos, movimentação de estoque de insumos e escalas de funcionários.

## 🎯 Objetivo
O principal objetivo da solução é garantir a rastreabilidade completa do atendimento hospitalar, oferecendo alta disponibilidade e segurança para os dados clínicos e gerenciais. O sistema busca evitar conflitos de ocupação de leitos, manter um histórico médico íntegro e suportar a absorção de dados em tempo real (como sinais vitais via IoT) para painéis de monitoramento, garantindo um tempo de resposta rápido para a equipe médica.

## 💻 Tecnologias Utilizadas
- MySQL / MariaDB
- MySQL Workbench
- MongoDB
- MongoDB Compass
- Python (geração de datasets)
- Git e GitHub

## 🏗️ Arquitetura de Dados
A solução utiliza uma abordagem híbrida de persistência (persistência poliglota) para atender aos requisitos funcionais e não funcionais:
- **MySQL (Relacional):** Armazena os dados estruturados e transacionais do hospital. Isso inclui cadastros de pacientes (incluindo atendimento provisório), funcionários, convênios, catálogo de exames e medicamentos, estrutura física (leitos e setores) e todo o fluxo assistencial (triagem, internação, solicitações, transferências e altas). O banco relacional possui **37 tabelas** normalizadas até a 3FN, garantindo integridade referencial e regras de negócio no próprio SGBD.
- **MongoDB (Não Relacional):** Responsável por dados de alto volume e esquema flexível. É utilizado para armazenar pacotes de telemetria IoT (sinais vitais contínuos), suportando até 5.000 inserções por segundo, além de manter logs de auditoria imutáveis (*append-only*) para rastreabilidade das ações no sistema.

## 📁 Estrutura do Repositório
A organização das pastas e arquivos do projeto segue o padrão abaixo:

```text
bd2-gestao-hospitalar/
│
├── README.md                                           # Documentação principal do projeto
├── .gitignore                                          # Arquivos ignorados pelo Git
│
├── docs/                                               # Documentação técnica e modelagem
│   ├── requisitos/                                     # Requisitos Funcionais (RFs) e Não Funcionais (RNFs)
│   ├── modelagem/                                      # Modelo ER (.mwb) e diagramas de arquitetura
│   ├── imagens/                                        # Exportações de diagramas e evidências
│   ├── dicionario_de_dados.pdf                         # Dicionário de Dados completo das 37 tabelas
│   ├── documentacao_mysql.md                           # Documentação do banco relacional (SQL, Views, EXPLAIN e DCL)
│   ├── doc_indices_mongodb.md                          # Estratégia de indexação e desempenho no MongoDB
│   └── docs_consultas_crud_aggregations_mongodb.md     # Documentação de CRUD e pipelines de agregação (NoSQL)
│
├── mysql/                                              # Scripts do banco de dados relacional
│   ├── ddl/                                            # Criação do banco e das 37 tabelas
│   ├── dml/                                            # Carga inicial (01_convenio.sql ... 37_alta.sql) e operacoes/ (01 a 11)
│   ├── consultas/                                      # 12 consultas analíticas e subpasta joins/ (01 a 07)
│   ├── views/                                          # 5 Views gerenciais e assistenciais
│   ├── procedures/                                     # 3 Stored Procedures transacionais e de consulta
│   ├── triggers/                                       # 3 Triggers de validação de estoque e controle de leitos
│   ├── indices/                                        # Criação de 10 índices compostos, análise EXPLAIN e remoção
│   ├── dcl/                                            # Criação de perfis de acesso e permissões (01_dcl_perfis.sql)
│   └── dump/                                           # Dump completo (.sql) com estrutura, dados e rotinas
│
└── mongodb/                                            # Scripts e arquivos do banco não relacional
    ├── dados/                                          # Script Python (gerar_datasets_mongodb.py) e subpasta datasets/ com os 4 JSONs
    ├── consultas/                                      # Scripts de consulta e pipelines de agregação
    └── indices/                                        # Criação e análise de índices no MongoDB
```

## 🚀 Como Executar o Projeto

### 1. Banco Relacional (MySQL / MariaDB via MySQL Workbench)
* **Opção A — Restauração rápida via Dump:**
  1. Abra o **MySQL Workbench** e conecte-se à instância local (`root`).
  2. Acesse **Server → Data Import**, selecione **Import from Self-Contained File** e aponte para o arquivo `.sql` na pasta `mysql/dump/`.
  3. Clique em **Start Import** para restaurar automaticamente o esquema `gestao_emergencia_hospitalar`, as 37 tabelas, os mais de 30.000 registros, as Views, Procedures e Triggers.
* **Opção B — Execução sequencial dos scripts:**
  1. Execute os scripts de `mysql/ddl/` para criar o banco e as tabelas.
  2. Execute a carga inicial em `mysql/dml/` (`01` a `37`) e, em seguida, os scripts de `mysql/dml/operacoes/` (`01` a `11`).
  3. Crie os objetos programáveis executando os arquivos de `mysql/views/`, `mysql/procedures/` e `mysql/triggers/`.
  4. Aplique os índices em `mysql/indices/02_criar_indices.sql` e os perfis de segurança em `mysql/dcl/01_dcl_perfis.sql`.
  5. Para validar os resultados, execute os scripts em `mysql/consultas/` e `mysql/consultas/joins/`.

### 2. Banco Não Relacional (MongoDB via MongoDB Compass)
1. Para criar o banco de dados com os dados totais, acesse a pasta `mongodb/dados/` e execute o script Python `gerar_datasets_mongodb.py` (`python gerar_datasets_mongodb.py`). Ao rodar, o script utiliza os arquivos de `INSERT` do MySQL (`mysql/dml/`) como base para gerar automaticamente os **4 arquivos `.json`** dentro da pasta `datasets/`.
2. Abra o **MongoDB Compass** e conecte-se ao servidor local (`mongodb://localhost:27017`).
3. Crie o banco de dados do projeto e importe os 4 arquivos `.json` gerados em `mongodb/dados/datasets/` para suas respectivas *collections* (`Add Data → Import JSON or CSV file`).
4. Execute os scripts de `mongodb/indices/` e `mongodb/consultas/` pelo **Mongosh** embutido no Compass ou via extensão do VS Code para criar os índices e rodar as agregações.

## ⚖️ Comparativo Crítico: Relacional (MySQL) vs. Não Relacional (MongoDB)

| Critério | MySQL (Relacional) | MongoDB (Não Relacional) |
|---|---|---|
| **Modelo de Dados** | Tabular e normalizado (3FN, 37 tabelas), com esquema rígido e chaves estrangeiras. | Orientado a documentos (BSON/JSON), com esquema flexível e aninhamento de atributos. |
| **Consistência e Transações** | **ACID** estrito (`InnoDB`), bloqueios transacionais (`FOR UPDATE`) e validação imediata via `CHECK`, `Triggers` e `Procedures`. | Alta vazão de escrita e consistência eventual configurável, sem overhead de travas relacionais entre tabelas. |
| **Consultas e Desempenho** | Excelente para cruzamentos complexos (`JOIN`s entre prontuário, exames, leitos e estoque) otimizados por índices B-Tree compostos. | Excelente para ingestão massiva contínua e leituras de séries temporais/eventos via *Aggregation Framework*. |
| **Papel no Hospital** | Núcleo transacional e cadastral, onde não pode haver dupla alocação de leito, saldo negativo de medicamentos ou perda de histórico clínico. | Camada de telemetria IoT (sinais vitais em tempo real) e logs imutáveis (*append-only*) de auditoria do sistema. |

> **Síntese arquitetural:** Nenhum dos dois modelos isoladamente resolveria todos os requisitos com eficiência. O **MySQL** garante a integridade referencial e atômica das decisões clínicas e administrativas, enquanto o **MongoDB** absorve o volume intenso de leituras de sensores e registros de auditoria sem degradar o desempenho do banco transacional.

## 🏁 Conclusão e Lições Aprendidas
O desenvolvimento deste projeto evidenciou na prática como decisões de modelagem e engenharia de dados impactam diretamente a confiabilidade e a velocidade de sistemas críticos:

- **Integridade na camada de dados:** a normalização até a 3FN eliminou redundâncias cadastrais, enquanto o uso de *Triggers* (`trg_validar_saida_estoque`, `trg_ocupar_leito`, `trg_liberar_leito`) e *Stored Procedures* (`sp_encerrar_internacao`) garantiu que regras críticas de negócio fossem cumpridas independentemente da aplicação cliente.
- **Impacto mensurável da indexação:** a análise dos planos de execução (`EXPLAIN`) antes e depois da criação dos 10 índices compostos comprovou a eliminação de *Full Table Scans* (`ALL`) nas tabelas transacionais e a resolução de consultas diretamente nos índices (*Covering Indexes* / `Using index`).
- **Segurança e menor privilégio:** a segmentação de usuários via DCL (`dba`, `medico`, `recepcao` e `analista`) demonstrou como restringir o acesso a colunas sensíveis (como senhas e CPFs) sem comprometer a operação diária.
- **Persistência poliglota:** integrar MySQL e MongoDB consolidou o entendimento de que escolher o SGBD adequado para cada natureza de dado — transacional estruturado vs. eventos de alta frequência — resulta em uma arquitetura mais escalável, segura e sustentável.

---

## 👥 Integrantes
- Ana Julia de Oliveira (RA: 02410684) - GitHub: [Ana868julia](https://github.com/Ana868julia)
- Felipe Soares Ferreira Leite (RA: 02410623) - GitHub: [felipesoaresfl](https://github.com/felipesoaresfl)
- Gustavo Cuoghi Bellato (RA: 02410213) - GitHub: [GustavoCBellato](https://github.com/GustavoCBellato)
- Marcos Vinícius Esaú dos Santos (RA: 02410039) - GitHub: [Marcos-2864](https://github.com/Marcos-2864)
- Saulo Ezequiel Jesus dos Santos (RA: 02410956) - GitHub: [SauloJsS](https://github.com/SauloJsS)

## 🎓 Disciplina
Banco de Dados II - Curso de Engenharia da Computação (Universidade do Vale do Paraíba - UNIVAP).  
Professor: André Olímpio.