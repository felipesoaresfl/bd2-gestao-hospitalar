USE gestao_emergencia_hospitalar;

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
