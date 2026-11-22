# Carga dos dados no MongoDB

Banco: `gestao_emergencia_hospitalar` · 4 collections · **106.336 documentos**, montados a partir dos INSERTs do MySQL (`mysql/dml/01` a `37`).

| Arquivo | Collection | Documentos |
|---|---|---:|
| `telemetria_sinais_vitais.json` | `telemetria_sinais_vitais` | 75.013 |
| `logs_auditoria.json` | `logs_auditoria` | 27.704 |
| `intercorrencias_atendimento.json` | `intercorrencias_atendimento` | 1.419 |
| `linha_tempo_atendimento.json` | `linha_tempo_atendimento` | 2.200 |
| | **Total** | **106.336** |

Cada arquivo tem um documento por linha. As datas estão no formato Extended JSON (`{"$date": "2026-04-02T01:05:52Z"}`) e entram no banco como `Date`.

## 1. Importar os 4 arquivos

### Pelo MongoDB Compass

1. Conecte em `mongodb://localhost:27017`.
2. Crie o banco `gestao_emergencia_hospitalar` com a primeira collection, `telemetria_sinais_vitais`.
3. Na collection, clique em **Add Data → Import JSON or CSV file**, escolha `mongodb/dados/telemetria_sinais_vitais.json` e confirme **Import**.
4. Repita para `logs_auditoria`, `intercorrencias_atendimento` e `linha_tempo_atendimento`, cada uma com o arquivo de mesmo nome.

### Pelo terminal (`mongoimport`)

Na raiz do repositório:

```bash
mongoimport --uri "mongodb://localhost:27017" --db gestao_emergencia_hospitalar --collection telemetria_sinais_vitais --file mongodb/dados/telemetria_sinais_vitais.json
```

```bash
mongoimport --uri "mongodb://localhost:27017" --db gestao_emergencia_hospitalar --collection logs_auditoria --file mongodb/dados/logs_auditoria.json
```

```bash
mongoimport --uri "mongodb://localhost:27017" --db gestao_emergencia_hospitalar --collection intercorrencias_atendimento --file mongodb/dados/intercorrencias_atendimento.json
```

```bash
mongoimport --uri "mongodb://localhost:27017" --db gestao_emergencia_hospitalar --collection linha_tempo_atendimento --file mongodb/dados/linha_tempo_atendimento.json
```

## 2. Inserção manual (`insertOne` e `insertMany`)

Depois da importação, abra o `mongosh` (pode ser o shell do Compass) e rode o conteúdo de `mongodb/dados/01_insercao_manual.mongodb.js`.

O script usa um caso real da base: o paciente do atendimento 2128, internado no leito UTI-10 da UTI adulto com sepse. Ele recebe:
- novas leituras do monitor;
- uma intercorrência aberta de hipotensão;
- registros de auditoria do médico intensivista;
- 2 intercorrências de teste com a tag `teste_exclusao`, para usar nos exercícios de DELETE.

O script também cria a linha do tempo do atendimento 2201, que é o paciente cadastrado por `mysql/dml/operacoes/01_insert_chegada_de_paciente.sql`.

## 3. Conferência no `mongosh`

```javascript
use("gestao_emergencia_hospitalar");
db.telemetria_sinais_vitais.countDocuments();
db.logs_auditoria.countDocuments();
db.intercorrencias_atendimento.countDocuments();
db.linha_tempo_atendimento.countDocuments();
```

| Collection | Só a importação | Com a inserção manual |
|---|---:|---:|
| `telemetria_sinais_vitais` | 75.013 | 75.017 |
| `logs_auditoria` | 27.704 | 27.708 |
| `intercorrencias_atendimento` | 1.419 | 1.422 |
| `linha_tempo_atendimento` | 2.200 | 2.201 |
| **Total** | **106.336** | **106.348** |
