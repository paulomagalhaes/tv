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
	   Statusdocontrato(c.status) cStatus,
       c.data_inicio cInicio,
       c.data_fim cFim,
       p."Data Incício" pInicio,
       p."Data Fim"     pFim
FROM   promocao_aplicacao pa,
       r_promocao p,
       contrato_assinante c
WHERE  p."Categoria" = 'Retencao'
       AND p.id = pa.id_promocao
       AND c.id = pa.id_contrato


create table AL_PROMO_BENE AS SELECT d.id_promocao,
       d.data_inicio,
       d.data_fim
FROM   desconto d,
       promocao p
WHERE  d.id_promocao = p.id
       AND p.categoria = 'Retencao' 


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
/*+ use_nl_with_index */
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


SELECT /*+ ORDERED  use_nl(p d a) */
    d.id_promocao,
       d.data_inicio,
       d.data_fim
FROM   promocao p,
  desconto d,  
--       desconto_assinatura_geral da, 
       assinatura a,
       contrato_assinante c
WHERE  d.id_promocao = p.id
       AND p.categoria = 'Retencao'
--       AND d.id_desconto_geral = da.id 
       and a.id_contrato = c.id
       and a.id = d.id_assinatura






create table AL_PROMO_BENE AS SELECT d.id_promocao,
       d.data_inicio,
       d.data_fim
FROM   desconto d,
       promocao p
WHERE  d.id_promocao = p.id
       AND p.categoria = 'Retencao' 
CREATE OR replace VIEW r_promocao
AS
  SELECT p.id,
         p.descricao                                          "Nome",
         p.data_inicio                                        "Data Incício",
         p.data_fim                                           "Data Fim",
         p.categoria                                          "Categoria",
         Decode(p.is_permanencia, 'T', 'Com',
                                  'Sem')
            "Compromisso de Permanência",
         Decode(p.is_permanencia, 'T', Decode(p.tipo_objeto_permanencia, 'P',
                                       'Na Promoção',
                                       'No Contrato'))
            "Tipo de Compromisso",
         Decode(p.is_permanencia, 'T', Decode(p.tipo_permanencia, 'M',
                                       'Multa '
                                       || Decode(p.is_multa_proporcional, 'T',
                                          'Proporcional',
                                                                          'Fixa'
                                          ),
                                                                  'Estorno'),
                                  '')
            "Quebra de Compromisso",
         p.minimo_dias_de_permanencia
            "Tempo de Permanência",
         Decode(p.valor_multa, NULL, '',
                               Decode(p.indice_multa, 1471, 'R$ ',
                                                      '')
                               || Trim(To_char(p.valor_multa, '9999999990D99',
                                       'NLS_NUMERIC_CHARACTERS = '',.'''))
                               || Decode(p.indice_multa, 1470, ' %',
                                                         '')) "Valor da Multa",
         'Condições:'
         || Chr (13)
         || Chr (10)
         || Trim (Substr(p.explicacao, 3, Instr(p.explicacao, ''' ''', 1, 1) - 3
                  ))
         || Chr (13)
         || Chr (10)
         || 'Banefícios:'
         || Chr (13)
         || Chr (10)
         || Trim (Substr (p.explicacao, Instr(p.explicacao, ''' ''', 1, 1) + 3,
                     Instr (
                           p.explicacao, ''' ''', 1, 2) -
                     Instr(p.explicacao, ''' ''', 1, 1)
                     - 3))
         || Chr (13)
         || Chr (10)
         || 'Validade e outras informações:'
         || Chr (13)
         || Chr (10)
         || Trim (Substr (p.explicacao, Instr(p.explicacao, ''' ''', 1, 2) + 3,
                           Length (p.explicacao) - Instr (p.explicacao, ''' ''',
                                                   1
                                                   , 2)
                           - 4))                              "Descrição"
  FROM   promocao p
  WHERE  p.classe = 38 


