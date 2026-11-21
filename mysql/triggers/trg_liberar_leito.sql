DELIMITER //

CREATE TRIGGER trg_liberar_leito
AFTER UPDATE ON ocupacao
FOR EACH ROW
BEGIN

    IF OLD.data_hora_saida IS NULL
       AND NEW.data_hora_saida IS NOT NULL THEN

        IF NOT EXISTS (
            SELECT 1
            FROM ocupacao
            WHERE id_leito = OLD.id_leito
              AND data_hora_saida IS NULL
        ) THEN

            UPDATE leito
            SET status = 'L'
            WHERE id_leito = OLD.id_leito;

        END IF;

    END IF;

END //

DELIMITER ;
