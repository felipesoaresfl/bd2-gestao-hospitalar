DELIMITER //

CREATE TRIGGER trg_validar_saida_estoque
BEFORE INSERT ON movimentacao_estoque
FOR EACH ROW
BEGIN

    DECLARE v_saldo INT DEFAULT 0;

    IF NEW.tipo = 'S' THEN

        SELECT COALESCE(
            SUM(
                CASE
                    WHEN tipo = 'E' THEN quantidade
                    WHEN tipo = 'S' THEN -quantidade
                    ELSE 0
                END
            ), 0
        )
        INTO v_saldo
        FROM movimentacao_estoque
        WHERE id_insumo = NEW.id_insumo
          AND id_estoque = NEW.id_estoque;

        IF NEW.quantidade > v_saldo THEN

            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Estoque insuficiente para realizar a saida';

        END IF;

    END IF;

END //

DELIMITER ;
