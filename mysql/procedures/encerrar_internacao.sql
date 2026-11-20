DELIMITER //

CREATE PROCEDURE sp_encerrar_internacao(
    IN p_id_internacao INT
)
BEGIN

    DECLARE v_status CHAR(1);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT status
    INTO v_status
    FROM internacao
    WHERE id_internacao = p_id_internacao
    FOR UPDATE;

    IF v_status <> 'A' THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Internacao inexistente ou ja encerrada';

    END IF;

    UPDATE internacao
    SET
        data_hora_saida = CURRENT_TIMESTAMP,
        status = 'E'
    WHERE id_internacao = p_id_internacao;

    UPDATE ocupacao
    SET data_hora_saida = CURRENT_TIMESTAMP
    WHERE id_internacao = p_id_internacao
      AND data_hora_saida IS NULL;

    COMMIT;

END //

DELIMITER ;
