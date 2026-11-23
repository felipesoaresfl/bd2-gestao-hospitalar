DELIMITER //

CREATE PROCEDURE sp_consultar_atendimentos_periodo(
    IN p_data_inicio DATE,
    IN p_data_fim DATE
)
BEGIN

    IF p_data_inicio IS NULL OR p_data_fim IS NULL
       OR p_data_inicio > p_data_fim THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Informe um periodo de datas valido';

    END IF;

    SELECT
        id_atendimento,
        paciente,
        status_atendimento,
        classificacao_risco,
        data_hora_entrada,
        queixa_principal
    FROM vw_atendimentos_detalhados
    WHERE data_hora_entrada >= p_data_inicio
      AND data_hora_entrada < DATE_ADD(p_data_fim, INTERVAL 1 DAY)
    ORDER BY data_hora_entrada;

END //

DELIMITER ;