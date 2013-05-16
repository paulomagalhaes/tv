 	

library(RJDBC)
drv <- JDBC("com.mysql.jdbc.Driver",
           "/etc/jdbc/mysql-connector-java-3.1.14-bin.jar",
           identifier.quote="`")
conn <- dbConnect(drv, "jdbc:oracle:thin:@oracle01:1521:objoi02", "", "")

extratos <- dbGetQuery(conn, "select
e.id,
e.id_contrato id_conta,
nvl(e.id_contato_postal_mc, nvl(e.id_cartao_de_credito_mc, nvl(id_conta_corrente_mc, nvl(id_conta_de_telefone_mc, id_conta_terceiro_mc)))) id_meio_de_cobranca,
decode(e.id_contato_postal_mc, null, decode(e.id_conta_corrente_mc, null, decode(e.id_cartao_de_credito_mc, null, decode(e.id_conta_de_telefone_mc, null, decode(e.id_conta_terceiro_mc, null, 'Outros', 'Conta de Terceiro'), 'Conta de Telefone'), 'Cartão de Crédito'), 'Débito em Conta Corrente'), 'Boleto Bancário') \"Tipo de Meio de Cobrança\",
e.numero_bancario \"Número Extrato\",
e.identificacao_do_banco \"Nosso Número\",
f.nome \"Financeira\",
e.data_criacao \"Data Emissão\",
e.data_vencimento \"Data Vencimento\",
e.data_cancelamento \"Data Cancelamento\",
b.data_ocorrencia \"Data Pagamento\",
b.valor \"Valor Pago\",
decode(b.status, null, decode(b.data_ocorrencia, null, '', 'Normal'), 'B', 'Baixa em duplicidade', 'P', 'Pagamento Inválido', 'R', 'Recuperação Inválida', 'T', 'Titulo não encontrado', 'I', 'Identificação Atrasada', 'S', 'Sequência de Saldos Inconsistente', 'F', 'Faltando atributos', 'Q', 'Qtd. de Tentativas Máxima', 'E', 'Erro Operacional', 'A', 'Anulada', 'ERRO') \"Situação da Baixa\",
n.data_negociacao \"Data Negociação\",
e.valor - nvl(e.valor_desconto_abatimento, 0) \"Valor Faturado\",
-nvl(e.valor_desconto_abatimento, 0) \"Valor Abatimento\",
case when e.data_cancelamento is not null then 'Cancelado' when n.data_negociacao is not null then 'Negociado' when e.status_quitado = 'Q' then 'Quitado' when b.data_ocorrencia is not null then 'Arrecadado' when e.data_vencimento <
(
   insistdate
)
then 'Vencido' else 'Faturado' end \"Status\"
from extrato_assinante e,
negociacao n,
negociacao_extratos ne,
financeira f,
(
   select
   b2.data_ocorrencia, b2.id_extrato, b2.valor, b2.status
   from
   (
      select
      b1.*, min(b1.data_baixa) over(partition by b1.id_extrato) min_data_baixa
      from baixa_assinante b1
   )
   b2
   where b2.min_data_baixa = b2.data_baixa
)
b
where e.id_financeira = f.id
and e.id = ne.id_extrato_assinante(+)
and ne.id_negociacao = n.id(+)
and b.id_extrato(+) = e.id")

save(extratos, file=file.path('data', 'extratos.RData'))
extratos$Status <- factor(extratos$Status)
extratos$'Situação da Baixa' <- factor(extratos$'Situação da Baixa')
extratos$'Tipo de Meio de Cobrança' <- factor(extratos$'Tipo de Meio de Cobrança')
extratos$'Financeira' <- factor(extratos$'Financeira')

extratos$'Data Emissão' <- as.Date(extratos$'Data Emissão')
extratos$'Data Vencimento' <- as.Date(extratos$'Data Vencimento')
extratos$'Data Cancelamento' <- as.Date(extratos$'Data Cancelamento')
extratos$'Data Pagamento' <- as.Date(extratos$'Data Pagamento')
extratos$'Data Negociação' <- as.Date(extratos$'Data Negociação')
extratos$'AnoMesPagamento' <- format(extratos$'Data Pagamento', '%Y-%m')
extratos$'AnoMesEmissao' <- format(extratos$'Data Emissão', '%Y-%m')

#e.by.conta <- aggregate (valor ~ ID_CONTA, extratos[!is.na(extratos$'Data Pagamento'),c('valor', 'ID_CONTA')], sum)

load('data/contratos.RData')
rec.por.contrato <- aggregate(extratos[!is.na(extratos$'Valor Pago') , c('ID_CONTA', 'Valor Pago')], by=list(extratos[!is.na(extratos$'Valor Pago') , ]$ID_CONTA), FUN=sum)
contrato.rec <- merge(contratos, rec.por.contrato, by.x="ID", by.y="Group.1")
#months <- length(seq(as.Date(contrato.rec$DATA_INSTALACAO), if(is.na(contrato.rec$DATA_FIM)) Sys.Date() else as.Date(contrato.rec$DATA_FIM), by="1 month") )

contrato.rec$dataFimOuHoje <- as.Date(sapply(contrato.rec$DATA_FIM, function (x) if (is.na(x)) as.Date("2013-05-02") else as.Date(x)) , as.Date('1970-01-01'))
contrato.rec$diasAtivo <- as.numeric(contrato.rec$dataFimOuHoje - as.Date(contrato.rec$DATA_INSTALACAO), units='days')
contrato.rec$diasAtivo[contrato.rec$diasAtivo == 0 ] <- 1
contrato.rec$arpu <- contrato.rec$'Valor Pago' / (contrato.rec$diasAtivo/30)

jpeg('graphics/arpuBoxplot.jpg', width=800, height=800)
boxplot(contrato.rec$arpu, outline=F, col="blue", ylab="Reais ($)", main="Receita por Contrato")
dev.off()

jpeg('graphics/TempoContratoBoxplot.jpg', width=800, height=800)
boxplot(contrato.rec$diasAtivo, outline=F, col="blue", ylab="Dias", main="Tempo de Contrato")
dev.off()


