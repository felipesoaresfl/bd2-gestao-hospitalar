USE gestao_emergencia_hospitalar;

ANALYZE TABLE atendimento, triagem, alta, internacao, sinais_vitais, solicitacao,
              resultado_exame, movimentacao_estoque, alergia, historico_clinico,
              paciente, cadastro_provisorio, leito;

-- Consulta 01: atendimentos por mês e forma de chegada
EXPLAIN
SELECT
    DATE_FORMAT(data_hora_entrada, '%Y-%m') AS mes,
    COUNT(*) AS atendimentos,
    SUM(CASE WHEN tipo_entrada = 'E' THEN 1 ELSE 0 END) AS espontanea,
    SUM(CASE WHEN tipo_entrada = 'A' THEN 1 ELSE 0 END) AS ambulancia_samu,
    SUM(CASE WHEN tipo_entrada = 'B' THEN 1 ELSE 0 END) AS bombeiros_policia,
    ROUND(100.0 * SUM(CASE WHEN tipo_entrada IN ('A', 'B') THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_chegada_por_resgate
FROM atendimento
GROUP BY DATE_FORMAT(data_hora_entrada, '%Y-%m')
ORDER BY mes;

-- Consulta 02: classificação de risco e espera até a triagem
EXPLAIN
SELECT
    cr.cor,
    cr.descricao,
    COUNT(*) AS atendimentos,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM triagem), 1) AS pct_do_total,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, a.data_hora_entrada, t.data_hora)), 1) AS media_min_ate_triagem,
    MAX(TIMESTAMPDIFF(MINUTE, a.data_hora_entrada, t.data_hora)) AS maior_espera_min
FROM triagem t
INNER JOIN classificacao_risco cr ON cr.id_classificacao = t.id_classificacao
INNER JOIN atendimento a ON a.id_atendimento = t.id_atendimento
GROUP BY cr.id_classificacao, cr.cor, cr.descricao, cr.prioridade
ORDER BY cr.prioridade;

-- Consulta 03: ocupação atual dos leitos por local
EXPLAIN
SELECT
    lo.nome AS local,
    COUNT(*) AS total_leitos,
    SUM(CASE WHEN l.status = 'O' THEN 1 ELSE 0 END) AS ocupados,
    SUM(CASE WHEN l.status = 'L' THEN 1 ELSE 0 END) AS livres,
    SUM(CASE WHEN l.status IN ('H', 'M') THEN 1 ELSE 0 END) AS indisponiveis,
    ROUND(100.0 * SUM(CASE WHEN l.status = 'O' THEN 1 ELSE 0 END) / COUNT(*), 1) AS taxa_ocupacao
FROM leito l
INNER JOIN local lo ON lo.id_local = l.id_local
GROUP BY lo.id_local, lo.nome
ORDER BY taxa_ocupacao DESC, lo.nome;

-- Consulta 04: diagnósticos mais frequentes nas altas
EXPLAIN
SELECT
    al.cid_final,
    COUNT(*) AS altas,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM alta WHERE tipo = 'M'), 1) AS pct_das_altas_medicas,
    ROUND(AVG(TIMESTAMPDIFF(YEAR, p.data_nasc, a.data_hora_entrada)), 0) AS idade_media
FROM alta al
INNER JOIN atendimento a ON a.id_atendimento = al.id_atendimento
INNER JOIN paciente p ON p.id_paciente = a.id_paciente
WHERE al.tipo = 'M'
  AND al.cid_final IS NOT NULL
GROUP BY al.cid_final
ORDER BY altas DESC
LIMIT 10;

-- Consulta 05: exames mais pedidos e taxa de alteração
EXPLAIN
SELECT
    e.nome AS exame,
    te.nome AS tipo_exame,
    COUNT(*) AS laudos,
    SUM(CASE WHEN r.situacao = 'A' THEN 1 ELSE 0 END) AS alterados,
    SUM(CASE WHEN r.situacao = 'C' THEN 1 ELSE 0 END) AS criticos,
    ROUND(100.0 * SUM(CASE WHEN r.situacao IN ('A', 'C') THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_fora_do_normal
FROM resultado_exame r
INNER JOIN solicitacao s ON s.id_solicitacao = r.id_solicitacao
INNER JOIN exame e ON e.id_exame = s.id_exame
INNER JOIN tipo_exame te ON te.id_tipo_exame = e.id_tipo_exame
GROUP BY e.id_exame, e.nome, te.nome
HAVING COUNT(*) >= 100
ORDER BY laudos DESC;

-- Consulta 06: pacientes que mais retornaram ao pronto-socorro
EXPLAIN
SELECT
    p.id_paciente,
    p.nome,
    TIMESTAMPDIFF(YEAR, p.data_nasc, MAX(a.data_hora_entrada)) AS idade,
    COUNT(*) AS atendimentos,
    MIN(a.data_hora_entrada) AS primeira_visita,
    MAX(a.data_hora_entrada) AS ultima_visita
FROM atendimento a
INNER JOIN paciente p ON p.id_paciente = a.id_paciente
GROUP BY p.id_paciente, p.nome, p.data_nasc
HAVING COUNT(*) >= 3
ORDER BY atendimentos DESC, ultima_visita DESC;

-- Consulta 07: tempo de permanência por tipo de internação
EXPLAIN
SELECT
    CASE tipo
        WHEN 'C' THEN 'Clínica'
        WHEN 'R' THEN 'Cirúrgica'
        WHEN 'U' THEN 'UTI'
    END AS tipo_internacao,
    COUNT(*) AS internacoes_encerradas,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, data_hora_entrada, data_hora_saida)) / 24.0, 1) AS media_dias,
    ROUND(MIN(TIMESTAMPDIFF(HOUR, data_hora_entrada, data_hora_saida)) / 24.0, 1) AS menor_dias,
    ROUND(MAX(TIMESTAMPDIFF(HOUR, data_hora_entrada, data_hora_saida)) / 24.0, 1) AS maior_dias
FROM internacao
WHERE status = 'E'
GROUP BY tipo
ORDER BY media_dias DESC;

-- Consulta 08: insumos mais consumidos e saldo atual
EXPLAIN
SELECT
    i.nome AS insumo,
    i.unidade_medida,
    SUM(m.quantidade) AS consumo_em_atendimentos,
    (
        SELECT SUM(CASE WHEN m2.tipo = 'E' THEN m2.quantidade ELSE -m2.quantidade END)
        FROM movimentacao_estoque m2
        WHERE m2.id_insumo = i.id_insumo
    ) AS saldo_atual_no_hospital,
    i.estoque_minimo
FROM movimentacao_estoque m
INNER JOIN insumo i ON i.id_insumo = m.id_insumo
WHERE m.tipo = 'S'
  AND m.id_solicitacao IS NOT NULL
GROUP BY i.id_insumo, i.nome, i.unidade_medida, i.estoque_minimo
ORDER BY consumo_em_atendimentos DESC
LIMIT 15;

-- Consulta 09: casos graves de pacientes alérgicos a medicamento
EXPLAIN
SELECT
    a.id_atendimento,
    p.nome AS paciente,
    cr.cor AS classificacao,
    a.data_hora_entrada,
    a.queixa_principal
FROM atendimento a
INNER JOIN paciente p ON p.id_paciente = a.id_paciente
INNER JOIN triagem t ON t.id_atendimento = a.id_atendimento
INNER JOIN classificacao_risco cr ON cr.id_classificacao = t.id_classificacao
WHERE cr.prioridade <= 2
  AND a.id_paciente IN (
        SELECT h.id_paciente
        FROM historico_clinico h
        INNER JOIN alergia al ON al.id_historico = h.id_historico
        WHERE al.tipo = 'M'
          AND al.gravidade IN ('M', 'G')
  )
ORDER BY a.data_hora_entrada DESC;

-- Consulta 10: aferições com sinais vitais de alerta
EXPLAIN
SELECT
    sv.data_hora,
    COALESCE(p.nome, cp.identificacao) AS paciente,
    sv.pressao_sistolica,
    sv.pressao_diastolica,
    sv.frequencia_cardiaca,
    sv.saturacao_o2,
    sv.temperatura
FROM sinais_vitais sv
INNER JOIN atendimento a ON a.id_atendimento = sv.id_atendimento
LEFT JOIN paciente p ON p.id_paciente = a.id_paciente
LEFT JOIN cadastro_provisorio cp ON cp.id_cadastro_provisorio = a.id_cadastro_provisorio
WHERE sv.saturacao_o2 < 90
   OR sv.pressao_sistolica < 90
   OR sv.temperatura >= 39.0
ORDER BY sv.data_hora DESC
LIMIT 30;

-- Consulta 11: atendimentos por convênio
EXPLAIN
SELECT
    COALESCE(c.nome, 'SUS / particular') AS convenio,
    COUNT(*) AS atendimentos,
    COUNT(DISTINCT a.id_paciente) AS pacientes,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM atendimento WHERE id_paciente IS NOT NULL), 1) AS pct_dos_atendimentos
FROM atendimento a
INNER JOIN paciente p ON p.id_paciente = a.id_paciente
LEFT JOIN convenio c ON c.id_convenio = p.id_convenio
GROUP BY c.id_convenio, c.nome
ORDER BY atendimentos DESC;

-- Consulta 12: tempo médio até o laudo por tipo de exame
EXPLAIN
SELECT
    te.nome AS tipo_exame,
    COUNT(*) AS laudos,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, s.data_hora, r.data_hora_resultado)) / 60.0, 1) AS media_horas_ate_laudo,
    ROUND(MIN(TIMESTAMPDIFF(MINUTE, s.data_hora, r.data_hora_resultado)) / 60.0, 1) AS mais_rapido_horas,
    ROUND(MAX(TIMESTAMPDIFF(MINUTE, s.data_hora, r.data_hora_resultado)) / 60.0, 1) AS mais_demorado_horas
FROM resultado_exame r
INNER JOIN solicitacao s ON s.id_solicitacao = r.id_solicitacao
INNER JOIN exame e ON e.id_exame = s.id_exame
INNER JOIN tipo_exame te ON te.id_tipo_exame = e.id_tipo_exame
WHERE s.prioridade = 'U'
GROUP BY te.id_tipo_exame, te.nome
HAVING AVG(TIMESTAMPDIFF(MINUTE, s.data_hora, r.data_hora_resultado)) > 60
ORDER BY media_horas_ate_laudo DESC;

-- Tempo real de execução (ms) nas consultas mais intensivas (MariaDB)
ANALYZE SELECT
    i.nome AS insumo,
    i.unidade_medida,
    SUM(m.quantidade) AS consumo_em_atendimentos,
    (
        SELECT SUM(CASE WHEN m2.tipo = 'E' THEN m2.quantidade ELSE -m2.quantidade END)
        FROM movimentacao_estoque m2
        WHERE m2.id_insumo = i.id_insumo
    ) AS saldo_atual_no_hospital,
    i.estoque_minimo
FROM movimentacao_estoque m
INNER JOIN insumo i ON i.id_insumo = m.id_insumo
WHERE m.tipo = 'S'
  AND m.id_solicitacao IS NOT NULL
GROUP BY i.id_insumo, i.nome, i.unidade_medida, i.estoque_minimo
ORDER BY consumo_em_atendimentos DESC
LIMIT 15;

ANALYZE SELECT
    sv.data_hora,
    COALESCE(p.nome, cp.identificacao) AS paciente,
    sv.pressao_sistolica,
    sv.pressao_diastolica,
    sv.frequencia_cardiaca,
    sv.saturacao_o2,
    sv.temperatura
FROM sinais_vitais sv
INNER JOIN atendimento a ON a.id_atendimento = sv.id_atendimento
LEFT JOIN paciente p ON p.id_paciente = a.id_paciente
LEFT JOIN cadastro_provisorio cp ON cp.id_cadastro_provisorio = a.id_cadastro_provisorio
WHERE sv.saturacao_o2 < 90
   OR sv.pressao_sistolica < 90
   OR sv.temperatura >= 39.0
ORDER BY sv.data_hora DESC
LIMIT 30;