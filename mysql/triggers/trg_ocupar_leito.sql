DELIMITER //

CREATE TRIGGER trg_ocupar_leito
AFTER INSERT ON ocupacao
FOR EACH ROW
BEGIN

    UPDATE leito
    SET status = 'O'
    WHERE id_leito = NEW.id_leito;

END //

DELIMITER ;
