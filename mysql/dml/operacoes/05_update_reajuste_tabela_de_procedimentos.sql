USE gestao_emergencia_hospitalar;

SET SQL_SAFE_UPDATES = 0;

UPDATE procedimento
SET valor = ROUND(valor * 1.045, 2)
WHERE valor IS NOT NULL;

SET SQL_SAFE_UPDATES = 1;

SELECT codigo, nome, valor
FROM procedimento
ORDER BY valor DESC;
