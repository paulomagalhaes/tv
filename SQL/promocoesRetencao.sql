/*
	conta quantos contratos tiveram mais do que uma promocao 
	de rentecao
*/
SELECT Count(*)
FROM   (SELECT id_contrato
        FROM   promocao_aplicacao pa,
               r_promocao p
        WHERE  p."Categoria" = 'Retencao'
               AND p.id = pa.id_promocao
        GROUP  BY id_contrato
        HAVING Count(id_contrato) > 1) 


/*
	Contratos com promocao de rentencao
*/
SELECT c.id,
	   Statusdocontrato(c.status) cStatus
       c.data_inicio cInicio,
       c.data_fim cFim,
       p."Data Incício" pInicio,
       p."Data Fim"     pFim
FROM   promocao_aplicacao pa,
       r_promocao p,
       contrato_assinante c
WHERE  p."Categoria" = 'Retencao'
       AND p.id = pa.id_promocao
       AND c.id = id_contrato


/*
	Distribuicao da quantidade de promocoes por contrato
*/
SELECT c.id,
       c.data_inicio,
       c.data_fim,
       Max(p."Data Incício") pInicio,
       Max(p."Data Fim")     pFim,
       Count(*)              promocoes
FROM   promocao_aplicacao pa,
       r_promocao p,
       contrato_assinante c
WHERE  p."Categoria" = 'Retencao'
       AND p.id = pa.id_promocao
       AND c.id = id_contrato
GROUP BY c.id,
          c.data_inicio,
          c.data_fim 

/*
	Conta o numero de contratos que tiveram  uma promocao de Retencao bem sucedida
*/
SELECT Count(DISTINCT id_contrato),
       Statusdocontrato(c.status) "Status"
FROM   promocao_aplicacao pa,
       r_promocao p,
       contrato_assinante c
WHERE  p."Categoria" = 'Retencao'
       AND p.id = pa.id_promocao
       AND c.id = id_contrato
       AND id_contrato_atual IS NULL
       AND pa.data_fim + ( 2 * ( pa.data_fim - pa.data_inicio ) ) < c.data_fim
       AND c.id IN (SELECT id_contrato
                    FROM   promocao_aplicacao pa,
                           r_promocao p
                    WHERE  p."Categoria" = 'Retencao'
                           AND p.id = pa.id_promocao
                    GROUP BY id_contrato
                    HAVING Count(id_contrato) = 1)
GROUP BY Statusdocontrato(c.status) 


