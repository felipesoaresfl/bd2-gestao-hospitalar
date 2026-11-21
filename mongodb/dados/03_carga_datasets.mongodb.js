use("gestao_emergencia_hospitalar");

const fs = require("fs");
const path = require("path");

const pasta = path.resolve(process.cwd(), "mongodb", "datasets");
const colecoes = [
  "telemetria_sinais_vitais",
  "logs_auditoria",
  "intercorrencias_atendimento",
  "linha_tempo_atendimento"
];
const tamanhoLote = 5000;
let total = 0;

for (const nome of colecoes) {
  const arquivo = path.join(pasta, nome + ".json");
  const linhas = fs.readFileSync(arquivo, "utf8").split("\n").filter((linha) => linha.trim() !== "");
  db.getCollection(nome).drop();
  for (let i = 0; i < linhas.length; i += tamanhoLote) {
    const lote = linhas.slice(i, i + tamanhoLote).map((linha) => EJSON.parse(linha));
    db.getCollection(nome).insertMany(lote, { ordered: false });
  }
  const quantidade = db.getCollection(nome).countDocuments();
  total += quantidade;
  print(nome.padEnd(32) + quantidade);
}

print("TOTAL".padEnd(32) + total);
