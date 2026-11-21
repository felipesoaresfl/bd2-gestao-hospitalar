# Carga dos dados no MongoDB

Banco: `gestao_emergencia_hospitalar` · 4 collections · **106.336 documentos** gerados a partir dos INSERTs do MySQL (`mysql/dml/01` a `37`).

| Collection | Documentos |
|---|---:|
| `telemetria_sinais_vitais` | 75.013 |
| `logs_auditoria` | 27.704 |
| `intercorrencias_atendimento` | 1.419 |
| `linha_tempo_atendimento` | 2.200 |
| **Total** | **106.336** |

Os arquivos completos (~70 MB) não vão para o GitHub. Eles são gerados em segundos pelo script e ficam em `mongodb/datasets/`. Em `mongodb/dados/amostras/` há 30 documentos de cada collection para consulta rápida.

## 1. Gerar os arquivos

Na raiz do repositório:

```bash
python mongodb/dados/gerar_datasets_mongodb.py
```

O script lê os arquivos `mysql/dml/*.sql`, usa os IDs, horários e funcionários reais e grava um arquivo NDJSON por collection (um documento por linha, datas no formato Extended JSON `{"$date": "...Z"}`, em UTC).

## 2. Carregar no MongoDB

### Opção A: `mongoimport` (MongoDB Database Tools)

```bash
mongoimport --uri "mongodb://localhost:27017" --db gestao_emergencia_hospitalar --collection telemetria_sinais_vitais --file mongodb/datasets/telemetria_sinais_vitais.json --drop
```

```bash
mongoimport --uri "mongodb://localhost:27017" --db gestao_emergencia_hospitalar --collection logs_auditoria --file mongodb/datasets/logs_auditoria.json --drop
```

```bash
mongoimport --uri "mongodb://localhost:27017" --db gestao_emergencia_hospitalar --collection intercorrencias_atendimento --file mongodb/datasets/intercorrencias_atendimento.json --drop
```

```bash
mongoimport --uri "mongodb://localhost:27017" --db gestao_emergencia_hospitalar --collection linha_tempo_atendimento --file mongodb/datasets/linha_tempo_atendimento.json --drop
```

As amostras são arrays JSON, então levam `--jsonArray`:

```bash
mongoimport --uri "mongodb://localhost:27017" --db gestao_emergencia_hospitalar --collection telemetria_sinais_vitais --file mongodb/dados/amostras/telemetria_sinais_vitais.json --jsonArray
```

### Opção B: só com o `mongosh` (sem instalar o Database Tools)

```bash
mongosh --file mongodb/dados/03_carga_datasets.mongodb.js
```

O script apaga e recria as 4 collections e carrega os arquivos em lotes de 5.000 com `insertMany`. Rode a partir da raiz do repositório.

## 3. Inserção manual (`insertOne` e `insertMany`)

Depois da carga:

```bash
mongosh --file mongodb/dados/01_insercao_manual.mongodb.js
```

Esse script usa um caso real da base: o paciente do atendimento 2128, internado no leito UTI-10 da UTI adulto com sepse. Ele recebe novas leituras do monitor, uma intercorrência aberta de hipotensão, registros de auditoria do médico intensivista e 2 intercorrências de teste marcadas com a tag `teste_exclusao`, para os exercícios de DELETE. Também cria a linha do tempo do atendimento 2201, aberto pelo script `mysql/dml/operacoes/01_insert_chegada_de_paciente.sql`.

A carga dos datasets apaga as collections. Por isso, se rodar de novo a carga, rode também a inserção manual depois.

## 4. Conferência no `mongosh`

```javascript
use("gestao_emergencia_hospitalar");
const colecoes = ["telemetria_sinais_vitais", "logs_auditoria", "intercorrencias_atendimento", "linha_tempo_atendimento"];
let total = 0;
colecoes.forEach((c) => { const n = db.getCollection(c).countDocuments(); total += n; print(c.padEnd(32) + n); });
print("TOTAL".padEnd(32) + total);
```

Resultado esperado: 106.336 só com a carga e 106.348 depois da inserção manual (4 leituras de telemetria, 4 logs, 3 intercorrências e 1 linha do tempo).
