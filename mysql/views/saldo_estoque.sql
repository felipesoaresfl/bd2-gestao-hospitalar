CREATE OR REPLACE VIEW vw_saldo_estoque AS
SELECT
    e.id_estoque,
    e.nome AS nome_estoque,
    i.id_insumo,
    i.nome AS insumo,
    i.tipo,
    i.unidade_medida,
    i.estoque_minimo,

    COALESCE(SUM(
        CASE
            WHEN m.tipo = 'E' THEN m.quantidade
            ELSE 0
        END
    ), 0) AS total_entradas,

    COALESCE(SUM(
        CASE
            WHEN m.tipo = 'S' THEN m.quantidade
            ELSE 0
        END
    ), 0) AS total_saidas,

    COALESCE(SUM(
        CASE
            WHEN m.tipo = 'E' THEN m.quantidade
            WHEN m.tipo = 'S' THEN -m.quantidade
            ELSE 0
        END
    ), 0) AS saldo_atual

FROM estoque e
CROSS JOIN insumo i
LEFT JOIN movimentacao_estoque m
    ON m.id_estoque = e.id_estoque
    AND m.id_insumo = i.id_insumo
GROUP BY
    e.id_estoque,
    e.nome,
    i.id_insumo,
    i.nome,
    i.tipo,
    i.unidade_medida,
    i.estoque_minimo;
