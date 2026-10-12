# 🏥 Sistema de Gestão de Emergências e Atendimento Hospitalar

## 📝 Descrição
O projeto consiste em um sistema abrangente projetado para otimizar e rastrear o fluxo de pacientes em um ambiente hospitalar de emergência. Ele abrange desde o cadastro inicial (incluindo pacientes sem identificação prévia) até a triagem pelo protocolo de classificação de risco, acompanhamento médico, solicitação de exames, internação e alta. A solução também gerencia a infraestrutura hospitalar, controlando leitos, equipamentos, movimentação de estoque de insumos e escalas de funcionários.

## 🎯 Objetivo
O principal objetivo da solução é garantir a rastreabilidade completa do atendimento hospitalar, oferecendo alta disponibilidade e segurança para os dados clínicos e gerenciais. O sistema busca evitar conflitos de ocupação de leitos, manter um histórico médico íntegro e suportar a absorção de dados em tempo real (como sinais vitais via IoT) para painéis de monitoramento, garantindo um tempo de resposta rápido para a equipe médica.

## 💻 Tecnologias Utilizadas
- MySQL
- MySQL Workbench
- MongoDB
- MongoDB Compass
- Git
- GitHub

## 🏗️ Arquitetura de Dados
A solução utiliza uma abordagem híbrida de persistência para atender aos requisitos funcionais e não funcionais:
- **MySQL (Relacional):** Armazena os dados estruturados e transacionais do hospital. Isso inclui cadastros de pacientes (criptografados), funcionários, convênios, catálogo de exames e medicamentos, estrutura física (leitos e setores) e todo o fluxo de atendimento transacional (triagem, internação, prescrições e transferências). O banco relacional possui 37 tabelas garantindo a integridade referencial.
- **MongoDB (Não Relacional):** Responsável por armazenar dados de alto volume e flexibilidade. É utilizado para o armazenamento de pacotes de dados de telemetria IoT (sinais vitais contínuos) suportando até 5000 inserções por segundo, além de manter os logs de auditoria imutáveis (append-only) para rastreabilidade de ações dos usuários no sistema.

## 📁 Estrutura do Repositório
A organização das pastas do projeto segue o padrão abaixo:

```text
bd2-gestao-hospitalar/
│
├── README.md                 # Documentação principal do projeto
├── .gitignore                # Arquivos ignorados pelo Git (credenciais, temporários)
│
├── docs/                     # Documentação geral
│   ├── requisitos/           # RFs e RNFs
│   └── modelagem/            # Diagramas ER, Dicionário de Dados e arquitetura
│   └── imagens/              # Exportações de imagens
│
├── mysql/                    # Scripts do banco de dados relacional
│   ├── ddl/                  # Criação de banco e tabelas (01_criacao_banco.sql, 02_criacao_tabelas.sql)
│   ├── dml/                  # Inserção de dados iniciais (03_insercao_dados.sql)
│   ├── consultas/            # Scripts de SELECT (04_consultas.sql)
│   ├── views/                # Criação de Views (05_views.sql)
│   ├── procedures/           # Stored Procedures (06_procedures.sql)
│   ├── triggers/             # Triggers de validação/automação (07_triggers.sql)
│   └── indices/              # Índices para otimização (08_indices.sql)
│
└── mongodb/                  # Scripts e arquivos do banco não relacional
    ├── dados/                # Arquivos JSON com datasets de exemplo (ex: logs.json)
    └── consultas/            # Scripts de consulta e agregação (consultas.mongodb.js)
```

## 👥 Integrantes
- Ana Julia de Oliveira (RA: 02410684) - Github: [Ana868julia](https://github.com/Ana868julia)
- Felipe Soares Ferreira Leite (RA: 02410623) - Github: [felipesoaresfl](https://github.com/felipesoaresfl)
- Gustavo Cuoghi Bellato (RA: 02410213) - Github: [GustavoCBellato](https://github.com/GustavoCBellato)
- Marcos Vinícius Esaú dos Santos (RA: 02410039) - Github: [Marcos-2864](https://github.com/Marcos-2864)
- Saulo Ezequiel Jesus dos Santos (RA: 02410956) - Github: [SauloJsS](https://github.com/SauloJsS)

## 🎓 Disciplina
Banco de Dados II - Curso de Engenharia da Computação (Universidade do Vale do Paraíba - UNIVAP).
Professor: André Olímpio.
