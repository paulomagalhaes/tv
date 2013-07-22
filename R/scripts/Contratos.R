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

pessoas <- dbGetQuery(conn, 
" SELECT 
      e.id id_endereco,
      e.\"Logradouro\",
      e.\"Número\",
      e.\"Complemento\",
      e.\"Bairro\",
      e.\"CEP\",
      e.\"Cidade\",
      e.\"UF\",
      e.\"POLO_NOME\",
      e.\"POLO_SIGLA\",
      c.id id_contrato,
      c.tipo_contrato,
      p.id id_pessoa,
      p.id_classificacao,
      p.\"TIPO\",
      p.nome,
      p.cgc_cpf,
      p.rg_inscricao,
      p.fantasia,
      p.ramo_atividade ,
      p.nascimento,
      p.sexo,
      p.email,
      p.nome_mae,
      p.nome_pai,
      p.is_funcionario_operadora,
      p.data_criacao,
      p.is_fraudador,
      p.is_suspeita_fraude,
      p.vip
FROM   al_pessoa p,
       al_contratos c,
       r_endereco e
WHERE  c.id_endereco_instalacao = e.id
       AND c.id_pessoa = p.id
       AND c.tipo_contrato = 'NORMAL DTH'  ")
save(pessoas, file=file.path('data', 'pessoas.RData'))
