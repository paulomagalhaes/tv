library(RJDBC)
drv <- JDBC("oracle.jdbc.driver.OracleDriver",
            "/Users/paulomagalhaes/Projects/OiTv/ojdbc6.jar")
conn <- dbConnect(drv, "jdbc:oracle:thin:@oracle01:1521:objoi02", "", "")

contratos <- dbGetQuery(conn, 
"SELECT c.id,
       c.id_pessoa,
       c.id_contrato_conta,
       c.id_vendedor,
       c.id_endereco_instalacao,
       c.id_contato_postal_mc,
       c.id_conta_corrente_mc,
       c.id_cartao_de_credito_mc,
       c.id_conta_de_telefone_mc,
       c.id_conta_terceiro_mc,
       Decode(c.id_contato_postal_mc, NULL, Decode(c.id_conta_corrente_mc, NULL,
                                            Decode
                                            (c.id_cartao_de_credito_mc, NULL,
       Decode
       (c.id_conta_de_telefone_mc, NULL,
       Decode(c.id_conta_terceiro_mc, NULL,
       'Outros'
       ,
       'Conta de Terceiro'),
       'Conta de Telefone'),
       'Cartão de Crédito'),
       'Débito em Conta Corrente'),
                                      'Boleto Bancário') meioCobranca,
       c.dia_de_cobranca,
       c.data_inicio,
       c.data_instalacao,
       c.data_venda,
       c.data_pedido_cancelamento,
       c.data_fim,
       m.nome,
       Statusdocontrato(c.status),
       t.nome                                            tipo_contrato,
       c.valor_saldo_atual_cobrado,
       c.valor_saldo_atual ,
       c.unidades
FROM   tipo_contrato t,
       contrato_assinante c,
       contrato_cancelamento_motivo m,
       contrato_assinante conta
WHERE  c.id_tipo_contrato = t.id
       AND t.tipo_agrupamento != 'C'
       AND c.id_motivo_cancelamento = m.id (+) ")
save(contratos, file=file.path('data', 'contratos.RData'))

