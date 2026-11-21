DELIMITER //

CREATE PROCEDURE sp_registrar_movimentacao_estoque(
    IN p_id_insumo INT,
    IN p_id_estoque INT,
    IN p_id_funcionario INT,
    IN p_tipo CHAR(1),
    IN p_quantidade INT,
    IN p_lote VARCHAR(30),
    IN p_data_validade DATE,
    IN p_id_solicitacao INT
)
BEGIN

    IF p_quantidade IS NULL OR p_quantidade < 1 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A quantidade deve ser maior que zero';

    END IF;

    IF p_tipo NOT IN ('E', 'S', 'A') OR p_tipo IS NULL THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tipo de movimentacao invalido';

    END IF;

    INSERT INTO movimentacao_estoque (
        id_insumo,
        id_estoque,
        id_funcionario,
        id_solicitacao,
        tipo,
        quantidade,
        lote,
        data_validade
    )
    VALUES (
        p_id_insumo,
        p_id_estoque,
        p_id_funcionario,
        p_id_solicitacao,
        p_tipo,
        p_quantidade,
        p_lote,
        p_data_validade
    );

END //

DELIMITER ;
