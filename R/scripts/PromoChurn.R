 	

library(RJDBC)

drv <- JDBC("oracle.jdbc.driver.OracleDriver",
            "/Users/paulomagalhaes/Projects/tv/ojdbc6.jar")
conn <- dbConnect(drv, "jdbc:oracle:thin:@oracle01:1521:objoi02", "oidth0205", "oidth0205")
promo.ret <- dbGetQuery(conn, 
"SELECT /*+ ORDERED  use_nl(p d a) */
      c.id,
      Statusdocontrato(c.status) cStatus,
      c.data_inicio cInicio,
      c.data_fim cFim,
      d.id_promocao,
      min(d.data_inicio) pInicio,
      max(d.data_fim) pDfim keep (dense_rank first order by d.data_fim desc nulls first) 
FROM   promocao p,
      desconto d,  
       assinatura a,
       contrato_assinante c
WHERE  d.id_promocao = p.id
       AND p.categoria = 'Retencao'
       and a.id_contrato = c.id
       and a.id = d.id_assinatura
group by       c.id,
       c.data_inicio,
       c.data_fim,
        d.id_promocao,
        Statusdocontrato(c.status)")

promo.freq <- dbGetQuery(conn, 
"SELECT c.id, c.data_inicio, c.data_fim, count(*) promocoes
FROM   promocao_aplicacao pa,
       r_promocao p,
       contrato_assinante c
WHERE p.\"Categoria\" = 'Retencao'
       AND p.id = pa.id_promocao
       AND c.id = id_contrato       
GROUP BY c.id, c.data_inicio, c.data_fim")

promo.ret <- dbGetQuery(conn,
	"SELECT c.id,
      pa.id paid,
      Statusdocontrato(c.status) cStatus,
      c.data_inicio cInicio,
      c.data_fim cFim,
      d.data_inicio pInicio,
      d.data_fim pFim
      FROM promocao_aplicacao pa, r_promocao p, contrato_assinante c, desconto d
      WHERE p.\"Categoria\" = 'Retencao'
      AND p.id = pa.id_promocao
      AND c.id = id_contrato)
      AND d.id_promocao = p.id")

promo.eff <- dbGetQuery(conn,
" SELECT Trunc(c.data_fim) data,
       c.status,
       Count(c.id)       contratos
FROM   al_contratos c
WHERE  c.data_fim IS NOT NULL
       AND status = 'Cancelado Espont.'
GROUP BY Trunc(c.data_fim),
          c.status
UNION
SELECT Trunc(pa.data_inicio)          data,
       'Promo Retencao'               status,
       Count(pa.id_contrato) contratos
FROM   promocao_aplicacao pa,
       r_promocao p
WHERE  p.\"Categoria\" = 'Retencao'
       AND p.id = pa.id_promocao  
GROUP BY Trunc(pa.data_inicio)")


save(promo.ret, file=file.path('data', 'promo.ret.RData'))

promo.eff.y <- aggregate(CONTRATOS ~ substr(DATA,1,4) + STATUS, data=promo.eff, sum)
colnames(promo.eff.y) <- c('Ano', 'Status', 'Contratos')
library(ggplot2)
library(scales)
jpeg('graphics/EfficienciaCelulaRetencao.jpg', width=800, height=800)
ggplot(promo.eff.y, aes(x=Ano, y=Contratos, fill=Status), order=desc(Status)) + geom_bar(stat="identity") + scale_y_continuous(labels = comma, name='Tentativas de Cancelamento') +ggtitle("Eficiênca da Celula de Retenção")
dev.off()

result <- t(as.matrix(character(3)))

for (i in 1:nrow(promo.ret)){
	pDays <- seq(as.Date(promo.ret[i, 'PINICIO']), if(is.na(as.Date(promo.ret[i, 'PFIM']))) Sys.Date() else as.Date(promo.ret[i, 'PFIM']), by="1 month")
	result <- rbind (result, cbind(promo.ret[i,'ID'], promo.ret[i,'CSTATUS'], pDays))
	if (i %% 1021 == 0) {print(i)}
}

for (x in promo.ret[1:10,]){
	print(x['PINICIO'])
}

extendDF <- function(x) {
    foo <- function(i, z) {
        freq <- seq(as.Date(z[i, 'PINICIO']), if(is.na(as.Date(z[i, 'PFIM']))) Sys.Date() else as.Date(z[i, 'PFIM']), by="1 month")
        times <- length(freq)
        out <- data.frame(freq,
                          rep(z[i, 'ID'], times),
                          rep(z[i, 'CSTATUS'], times))
        #names(out) <- names(z)
        if (i %% 1021 == 0) {print(i)}
        out
    }
    out <- lapply(seq_len(nrow(x)), FUN = foo, z = x)
    do.call("rbind", out)
}


#seq(as.Date(promo.ret[i, 'PINICIO']), if(is.na(as.Date(promo.ret[i, 'PFIM']))) Sys.Date() else as.Date(promo.ret[i, 'PFIM']), by="1 month")
promo.ret <- promo.ret[!is.na(promo.ret$PFIM), ]
promo.ret$dataFimOuHoje <- as.Date(sapply(promo.ret$PFIM, function (x) if (is.na(x)) as.Date("2013-05-02") else as.Date(x)) , as.Date('1970-01-01'))
promo.ret$diasPromocao <- as.numeric(as.Date(promo.ret$PFIM) - as.Date(promo.ret$PINICIO), units="days")
promo.ret$diasAtePromocao <- as.numeric(as.Date(promo.ret$CINICIO) - as.Date(promo.ret$PINICIO), units="days")


promo.ret$promoDataFimOuHoje <- as.Date(sapply(promo.ret$PFIM, function (x) if (is.na(x)) as.Date("2013-05-02") else as.Date(x)) , as.Date('1970-01-01'))

promo.ret$contratoDataFimOuHoje <- as.Date(sapply(promo.ret$CFIM, function (x) if (is.na(x)) as.Date("2013-05-02") else as.Date(x)) , as.Date('1970-01-01'))
promo.ret$diasAposFimPromo <- as.numeric(promo.ret$contratoDataFimOuHoje - promo.ret$promoDataFimOuHoje, units="days") 
ggplot(promo.ret, aes(x=diasAposFimPromo)) + geom_histogram(fill=status)


# promodel
library(foreign)
library(e1071)
df.orig <- read.spss('/Users/paulomagalhaes/Projects/tv/R/data/vi_MAIS_VD.sav', to.data.frame=T)
colnames(df.orig)[54:81] <- c("PontoTVDTH","Principal","OiTVMaisHD","OiTVMais","+Canais","HBO/Max","SexyPrivê","Telecine","OiTVMaisTelecine","Estadual+SérieA","OiTVMaisHBOMax","OiTVMaisTelecineHD","OiTVMaisHBO/MAXHD","OiTVMega","PontoTVBRI","OiTVSimples","OiTVMaisCinemaHD","OiTVLigadoBRI","SexyHot","OiTVMaisCinema","OiTVMegaCinemaHD","HBO","SexyHot+PlayboyTV","OiTVMegaCinema","Combate","Estadual+SérieA+B","OiTVMegaHD","Outros")
promo.desc <- data.frame( 
  ID_PROMOCAO=c("1097019793", "1097029180", "1174723088", "1175046129", "1332457485", "1332275241", "1097029095", "1481739001", "1097029112", "1401260703", "1174731128", "1097029129", "1097029146", "1097029163", "1180821621", "1481780980", "1326909370", "508669727", "571411632", "776087752", "883967237", "883748391", "883919045", "1013464390", "1013440033", "883799325", "978346443", "978354044", "397413647", "484473302", "571899095", "1013249407", "1013736252", "1153090313", "1153091175", "1205231156", "1205231609", "1205238654", "1205240586", "1298709644", "1298944137", "1299051653", "1299091651", "1344430619", "1351764959", "1396135703", "1401715952", "1659114061", "1659228087", "1659294224", "1662702525", "1662790167", "1662839624", "1821414878", "1821429960", "1821707782", "1875736828", "1875893339", "1876331848", "1877193783", "1877304733", "1877357021", "2117602752", "2118093538", "2385067196", "2385140580", "2385267137", "2385770670", "2385811779", "2386582387", "2503593492", "2504049463", "2504867510", "2505085473", "2505416110", "2505722482", "3074497669", "3075072433", "3075190171", "3078495908", "3078925715"), 
  PROMO_DESC = c("Oi TV Mais - 540", "OI TV Mais - 420", "Oi TV Mais  HBO Max  / Boleto - 420", "Oi TV Mais / Boleto - 480", "Oi Tv Mais / Concorrencia - 260", "Oi Tv Mais / Concorrencia / Boleto - 160", "Oi TV Mais HBO Max - 450", "Oi TV Mais HBO Max - 390", "Oi TV Mais Telecine - 540", "Oi TV Mais Telecine - 420", "Oi TV Mais Telecine / Boleto - 480", "Oi TV Mega - 540", "Oi TV Mega HBO Max - 540", "Oi TV Mega Telecine - 540", "Oi TV Simples - 480", "Oi TV Simples - 360", " Ponto adicional - 120", " 0 dias regiao 1 - 330", " 0 dias regiao 2 - 330", " 30 dias - 300", "Oi TV Simples - 300", "Oi TV Simples / Boleto - 180", "Oi TV Simples Canais+ - 330", "Oi TV Simples HBO Max - 180", "Oi TV Simples HBO Max Canais + - 210", "Oi TV Simples Telecine - 480", "Oi TV Simples Telecine Canais + - 270", "Oi TV Simples Telecine light - 180","397413647", "484473302", "571899095", "1013249407", "1013736252", "1153090313", "1153091175", "1205231156", "1205231609", "1205238654", "1205240586", "1298709644", "1298944137", "1299051653", "1299091651", "1344430619", "1351764959", "1396135703", "1401715952", "1659114061", "1659228087", "1659294224", "1662702525", "1662790167", "1662839624", "1821414878", "1821429960", "1821707782", "1875736828", "1875893339", "1876331848", "1877193783", "1877304733", "1877357021", "2117602752", "2118093538", "2385067196", "2385140580", "2385267137", "2385770670", "2385811779", "2386582387", "2503593492", "2504049463", "2504867510", "2505085473", "2505416110", "2505722482", "3074497669", "3075072433", "3075190171", "3078495908", "3078925715"))
df <- merge (df.orig, promo.desc, by="ID_PROMOCAO", all.x=T)
df$IDADE_RECEBE_PROMO <-  as.POSIXlt( df$PINICIO_PROMOCAO, origin="1582/10/14") - as.POSIXlt( df$CINICIO_CONTRATO, origin="1582/10/14")
##df$ID_PROMOCAO <- factor(as.character(df$ID_PROMOCAO))
#remove 54 incomplete cases
df <- df[!is.na(df$GAP_ATIVA_CRIA), ]
# remover caras que nunca pagaram um extratao(por que eles estao aqui)
df <- df[!is.na(df$Valor_Pago_sum), ]
promoClass <- apply(df, 1, function(x){ if(x['SUCESSO_FINAL'] == 'Fidelizado') { return (x['PROMO_DESC']) } else { return ('InFidel')}})
df <- cbind(df, promoClass)

df <- df[ , c('DUR_PROMO_DIA', 'DTCE_1_max','DSEN_4_max', 'DSB_4_max',  'N_BREAK_PROMOCOES', 'N_BREAK_extrato', 'N_BREAK_PACOTE', 'GAP_ATIVA_CRIA' , 'meses_na_base', 'Valor_Pago_sum', 'TIPO_COBRA_CONTRA', 'SemanaVencimento', "Principal","OiTVMaisHD","OiTVMais","+Canais","HBO/Max","SexyPrivê","Telecine","OiTVMaisTelecine","Estadual+SérieA","OiTVMaisHBOMax","OiTVMaisTelecineHD","OiTVMaisHBO/MAXHD","OiTVMega","OiTVSimples","OiTVMaisCinemaHD","SexyHot","OiTVMaisCinema","OiTVMegaCinemaHD","HBO","SexyHot+PlayboyTV","OiTVMegaCinema","Combate","Estadual+SérieA+B","OiTVMegaHD","Outros", 'ATENDIMENTOS', 'OS_EXTERNA', 'CEP', 'IDADE_RECEBE_PROMO', 'promoClass', 'ID_CONTRATO', 'PROMO_DESC', 'SUCESSO_FINAL', 'ID_PROMOCAO')]

df$CEP <- factor(substr( as.character(df$CEP),1,3))

df.success <- df[df$SUCESSO_FINAL == 'Fidelizado', ]
df.success <- do.call("rbind", as.list(
  by(df.success, df.success$ID_PROMOCAO, function(x){
    if(nrow(x) < 200 ){
      return(NA)
    }
    return (x[sample(1:nrow(x), 200),])
  }
)))
package.promos <- promo.desc [grep('Oi TV', as.character(promo.desc$PROMO_DESC)), ]
package.promos <- package.promos [grep('Boleto', as.character(package.promos$PROMO_DESC), invert=T), ]
package.promos <- package.promos[ !as.character(package.promos$ID_PROMOCAO) %in% c('883799325','883919045','883967237','978346443','978354044','1013440033','1013464390'),]
package.promos$ID_PROMOCAO <- factor(package.promos$ID_PROMOCAO)
df.success <-  df.success[(df.success$ID_PROMOCAO %in% as.character(package.promos$ID_PROMOCAO)),] 
df.success <- df.success [!is.na(df.success$SUCESSO_FINAL), ]
df.success$PROMO_DESC <- factor(df.success$PROMO_DESC)

df.nosuccess <- df[df$SUCESSO_FINAL != 'Fidelizado', ]
df.nosuccess <- df.nosuccess[df.nosuccess$PROMO_DESC %in% levels(df.success$PROMO_DESC),]
df.nosuccess$PROMO_DESC<- factor(df.nosuccess$PROMO_DESC)
#df.nosuccess <- df.nosuccess[sample(1:nrow(df.nosuccess), 1000),]
df.nosuccess <- do.call("rbind", as.list(
  by(df.nosuccess, df.nosuccess$ID_PROMOCAO, function(x){
    if(nrow(x) < 200 ){
      return(NA)
    }
    return (x[sample(1:nrow(x), 200),])
  }
)))


sample.idx <- sample(1:nrow(df.success),  nrow(df.success)*.8)
df.train <- df.success[sample.idx,] 
df.test <- df.success[-sample.idx,]

classifier<-naiveBayes(df.train[,1:44], df.train[,47])
predictions <- predict(classifier, df.test[,1:47]) 
sum(as.character(df.test$PROMO_DESC) == as.character(predictions))/nrow(df.test)

#table(df2$PROMO_DESC, df2$predict_desc)

df2 <- df.test
df2$accurate <- as.character(df.test$PROMO_DESC) == as.character(predictions)
ggplot(df2, aes(x=PROMO_DESC, fill=accurate)) +geom_bar() + theme(axis.text.x = element_text( angle=60, hjust=1))
#df2$PROMO<- factor(df2$PROMO, levels=unlist(sort(levels(df2$PROMO)))

#predictions <- predict(classifier, df.nosuccess[,1:42])
#sum(as.character(df.nosuccess$ID_PROMOCAO) != as.character(predictions))
# table(predictions, df.nosuccess[,45])

sample.idx <- sample(1:nrow(df.nosuccess),  nrow(df.nosuccess)*.7)
df.train <- df.nosuccess[sample.idx,] 
df.test <- df.nosuccess[-sample.idx,]

classifier<-naiveBayes(df.train[,1:44], df.train[,47])
predictions <- predict(classifier, df.test[,1:47]) 
sum(as.character(df.test$PROMO_DESC) != as.character(predictions))/nrow(df.test)

df2 <- df.test
df2$accurate <- as.character(df.test$PROMO_DESC) != as.character(predictions)
ggplot(df2, aes(x=PROMO_DESC, fill=accurate)) +geom_bar() + theme(axis.text.x = element_text( angle=60, hjust=1))

# df.balanced <- rbind(df.success, df.nosuccess)

# sample.idx <- sample(1:nrow(df.balanced),  nrow(df.balanced)*.7)
# df.train <- df.balanced[sample.idx,] 
# df.test <- df.balanced[-sample.idx,]

# classifier<-naiveBayes(df.train[,1:42], df.train[,43])
# predictions <- predict(classifier, df.test[,1:42])
#table(predictions, df.test[,43])

tmpPredictions <- as.character(predictions)
tmpPredictions[tmpPredictions!='InFidel' ] <- 'promo'
temp <- as.character(df.test$promoClass)

temp[temp!='InFidel'] <-  'promo'
table(tmpPredictions, temp)

#tmp <- data.frame( ID_PROMOCAO=c("1097019793", "1097029180", "1174723088", "1175046129", "1332457485", "1332275241", "1097029095", "1481739001", "1097029112", "1401260703", "1174731128", "1097029129", "1097029146", "1097029163", "1180821621", "1481780980", "1326909370", "508669727", "571411632", "776087752", "883967237", "883748391", "883919045", "1013464390", "1013440033", "883799325", "978346443", "978354044"), PROMO = c("Oi TV Mais - 540", "Oi TV Mais - 420", "Oi TV Mais  HBO Max  / Boleto - 420", "Oi TV Mais / Boleto - 480", "Oi Tv Mais / Concorrencia - 260", "Oi Tv Mais / Concorrencia / Boleto - 160", "Oi TV Mais HBO Max - 450", "Oi TV Mais HBO Max - 390", "Oi TV Mais Telecine - 540", "Oi TV Mais Telecine - 420", "Oi TV Mais Telecine / Boleto - 480", "Oi TV Mega - 540", "Oi TV Mega HBO Max - 540", "Oi TV Mega Telecine - 540", "Oi TV Simples - 480", "Oi TV Simples - 360", " Ponto adicional - 120", " 0 dias regiao 1 - 330", " 0 dias regiao 2 - 330", " 30 dias - 300", "Oi TV Simples - 300", "Oi TV Simples / Boleto - 180", "Oi TV Simples Canais+ - 330", "Oi TV Simples HBO Max - 180", "Oi TV Simples HBO Max Canais + - 210", "Oi TV Simples Telecine - 480", "Oi TV Simples Telecine Canais + - 270", "Oi TV Simples Telecine light - 180"))
df2 <- df
df2$PROMO_DESC<- factor(df2$PROMO_DESC, levels=unlist(dimnames(sort(table(df2$PROMO_DESC)))))
#df2$PROMO<- factor(df2$PROMO, levels=unlist(sort(levels(df2$PROMO)))
ggplot(df2[df2$ID_PROMOCAO %in%  unique(df.success$ID_PROMOCAO),], aes(x=PROMO_DESC, fill=SUCESSO_FINAL)) +geom_bar() + theme(axis.text.x = element_text( angle=60, hjust=1))

tmp <- no.suc.promo[as.character(no.suc.promo$ID_PROMOCAO) != as.character(no.suc.promo$predictions),]
ggplot(tmp, aes(x=ID_PROMOCAO)) + geom_histogram(position=identity)


  