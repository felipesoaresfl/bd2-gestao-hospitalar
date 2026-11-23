-- =====================================================================
-- DCL (2.11) - Perfis de acesso: gestao_emergencia_hospitalar
-- Rodar DEPOIS do script de criação do banco (DDL).
-- Perfis: DBA, médico, recepção e analista (somente leitura)
-- Os grants são por tabela (e por coluna no caso de funcionario) para
-- que ninguém, além do DBA, consiga ler funcionario.senha.
-- ATENÇÃO: troque as senhas antes de usar fora do ambiente da faculdade.
-- =====================================================================

USE gestao_emergencia_hospitalar;

-- ---------------------------------------------------------------------
-- 0) Limpeza (permite rodar o script mais de uma vez)
-- ---------------------------------------------------------------------
DROP USER IF EXISTS 'dba_emergencia'@'localhost';
DROP USER IF EXISTS 'medico_emergencia'@'localhost';
DROP USER IF EXISTS 'recepcao_emergencia'@'localhost';
DROP USER IF EXISTS 'analista_emergencia'@'localhost';

-- ---------------------------------------------------------------------
-- 1) CREATE USER
-- ---------------------------------------------------------------------
CREATE USER 'dba_emergencia'@'localhost'      IDENTIFIED BY 'Dba@2026!';
CREATE USER 'medico_emergencia'@'localhost'   IDENTIFIED BY 'Med@2026!';
CREATE USER 'recepcao_emergencia'@'localhost' IDENTIFIED BY 'Rec@2026!';
CREATE USER 'analista_emergencia'@'localhost' IDENTIFIED BY 'Ana@2026!';

-- ---------------------------------------------------------------------
-- 2) GRANT
-- ---------------------------------------------------------------------

-- 2.1 DBA: controle total sobre o banco do projeto
GRANT ALL PRIVILEGES ON gestao_emergencia_hospitalar.*
  TO 'dba_emergencia'@'localhost';

-- 2.2 Médico: lê o prontuário e o catálogo; registra o trabalho clínico
GRANT SELECT ON gestao_emergencia_hospitalar.paciente              TO 'medico_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.historico_clinico     TO 'medico_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.status_atendimento    TO 'medico_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.classificacao_risco   TO 'medico_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.triagem               TO 'medico_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.sinais_vitais         TO 'medico_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.procedimento          TO 'medico_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.tipo_exame            TO 'medico_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.exame                 TO 'medico_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.insumo                TO 'medico_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.resultado_exame       TO 'medico_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.leito                 TO 'medico_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.ocupacao              TO 'medico_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.local                 TO 'medico_emergencia'@'localhost';
-- o médico só enxerga dados não sensíveis dos funcionários (sem cpf, senha etc.)
GRANT SELECT (id_funcionario, id_cargo, nome, registro_profissional, status)
  ON gestao_emergencia_hospitalar.funcionario TO 'medico_emergencia'@'localhost';

GRANT SELECT, UPDATE         ON gestao_emergencia_hospitalar.atendimento     TO 'medico_emergencia'@'localhost';
GRANT SELECT, INSERT, UPDATE ON gestao_emergencia_hospitalar.solicitacao     TO 'medico_emergencia'@'localhost';
GRANT SELECT, INSERT, UPDATE ON gestao_emergencia_hospitalar.internacao      TO 'medico_emergencia'@'localhost';
GRANT SELECT, INSERT         ON gestao_emergencia_hospitalar.transferencia   TO 'medico_emergencia'@'localhost';
GRANT SELECT, INSERT         ON gestao_emergencia_hospitalar.alta            TO 'medico_emergencia'@'localhost';
GRANT SELECT, INSERT, UPDATE ON gestao_emergencia_hospitalar.doenca          TO 'medico_emergencia'@'localhost';
GRANT SELECT, INSERT, UPDATE ON gestao_emergencia_hospitalar.alergia         TO 'medico_emergencia'@'localhost';
GRANT SELECT, INSERT, UPDATE ON gestao_emergencia_hospitalar.cirurgia        TO 'medico_emergencia'@'localhost';
GRANT SELECT, INSERT, UPDATE ON gestao_emergencia_hospitalar.contraindicacao TO 'medico_emergencia'@'localhost';

-- 2.3 Recepção: cadastro de pacientes e abertura de atendimentos
GRANT SELECT, INSERT, UPDATE ON gestao_emergencia_hospitalar.paciente            TO 'recepcao_emergencia'@'localhost';
GRANT SELECT, INSERT, UPDATE ON gestao_emergencia_hospitalar.cadastro_provisorio TO 'recepcao_emergencia'@'localhost';
GRANT SELECT, INSERT, UPDATE ON gestao_emergencia_hospitalar.contato             TO 'recepcao_emergencia'@'localhost';
GRANT SELECT, INSERT, UPDATE ON gestao_emergencia_hospitalar.endereco            TO 'recepcao_emergencia'@'localhost';
GRANT SELECT                 ON gestao_emergencia_hospitalar.convenio            TO 'recepcao_emergencia'@'localhost';
GRANT SELECT                 ON gestao_emergencia_hospitalar.status_atendimento  TO 'recepcao_emergencia'@'localhost';
GRANT SELECT                 ON gestao_emergencia_hospitalar.local               TO 'recepcao_emergencia'@'localhost';
GRANT SELECT, INSERT, UPDATE ON gestao_emergencia_hospitalar.atendimento         TO 'recepcao_emergencia'@'localhost';

-- 2.4 Analista: somente leitura nas tabelas das consultas analíticas (sem cpf/senha)
GRANT SELECT ON gestao_emergencia_hospitalar.paciente              TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.cadastro_provisorio   TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.convenio              TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.historico_clinico     TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.alergia               TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.atendimento           TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.status_atendimento    TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.classificacao_risco   TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.triagem               TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.sinais_vitais         TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.solicitacao           TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.exame                 TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.tipo_exame            TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.resultado_exame       TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.internacao            TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.ocupacao              TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.transferencia         TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.alta                  TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.leito                 TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.local                 TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.insumo                TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.estoque               TO 'analista_emergencia'@'localhost';
GRANT SELECT ON gestao_emergencia_hospitalar.movimentacao_estoque  TO 'analista_emergencia'@'localhost';
GRANT SELECT (id_funcionario, id_cargo, nome, data_admissao, status)
  ON gestao_emergencia_hospitalar.funcionario TO 'analista_emergencia'@'localhost';
GRANT EXECUTE ON gestao_emergencia_hospitalar.* TO 'analista_emergencia'@'localhost';

-- ---------------------------------------------------------------------
-- 3) REVOKE
-- ---------------------------------------------------------------------
REVOKE INSERT, UPDATE ON gestao_emergencia_hospitalar.solicitacao
  FROM 'medico_emergencia'@'localhost';

REVOKE UPDATE ON gestao_emergencia_hospitalar.atendimento
  FROM 'recepcao_emergencia'@'localhost';

REVOKE EXECUTE ON gestao_emergencia_hospitalar.*
  FROM 'analista_emergencia'@'localhost';

REVOKE SELECT ON gestao_emergencia_hospitalar.transferencia
  FROM 'analista_emergencia'@'localhost';

FLUSH PRIVILEGES;

-- ---------------------------------------------------------------------
-- 4) Conferência (use nos prints do trabalho)
-- ---------------------------------------------------------------------
SHOW GRANTS FOR 'dba_emergencia'@'localhost';
SHOW GRANTS FOR 'medico_emergencia'@'localhost';
SHOW GRANTS FOR 'recepcao_emergencia'@'localhost';
SHOW GRANTS FOR 'analista_emergencia'@'localhost';
```[cite: 4, 11, 25]

---

## 2. Passo a passo de validação no MySQL Workbench (a partir de onde você está)

Como você já criou o banco, criou as 37 tabelas e rodou os `INSERT`s[cite: 3, 8], siga estes passos:

### Passo 1 — Rodar as operações do DML (`mysql/dml/operacoes/`) e conferir o total de registros
1. Execute os scripts da pasta `mysql/dml/operacoes/` (`01` a `11`)[cite: 8].
2. Rode uma contagem para confirmar o volume de registros e salvar um print:
```sql
USE gestao_emergencia_hospitalar;
SELECT SUM(linhas) AS total_registros FROM (
  SELECT COUNT(*) AS linhas FROM paciente
  UNION ALL SELECT COUNT(*) FROM atendimento
  UNION ALL SELECT COUNT(*) FROM triagem
  UNION ALL SELECT COUNT(*) FROM sinais_vitais
  UNION ALL SELECT COUNT(*) FROM solicitacao
  UNION ALL SELECT COUNT(*) FROM resultado_exame
  UNION ALL SELECT COUNT(*) FROM movimentacao_estoque
  UNION ALL SELECT COUNT(*) FROM alta
) t;